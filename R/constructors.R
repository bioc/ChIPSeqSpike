## Global variable definitions

#globalVariables(c("inputBamFile"))


## Main function called to create the different objects according to an info
## file provided as parameter.


.readInfoFile <- function(infoFile){
    
    if(isTRUE(all.equal(file_ext(infoFile), "csv"))){
        info_table <- read.csv(infoFile, stringsAsFactors = FALSE)
    }else if(isTRUE(all.equal(file_ext(infoFile), "txt"))){
        info_table <- read.table(infoFile, header = TRUE, sep = "\t", 
                stringsAsFactors = FALSE)
    }else
        stop("The info file should be in csv or txt format.")
    
    return(info_table)
}



.checkInfoFile <- function(info_table, expected_nb_col, colnames_vec){
    
    if(!(isTRUE(all.equal(ncol(info_table), expected_nb_col)) && 
                isTRUE(all.equal(colnames(info_table), 
                                colnames_vec))))
        stop("Columns are missing in your info file or one column has the ",
                "wrong name. Your file should contain the following column ",
                "names: ", paste(colnames_vec, collapse=","))
    
    if(isTRUE(all.equal(nrow(info_table), 0)))
        stop("File is empty.")
}


spikeDataset <- function(infoFile, bamPath, bigWigPath, boost = FALSE, 
        verbose = TRUE){
    
    info_table <- .readInfoFile(infoFile)
    colnames_vec <- c("expName", "endogenousBam", "exogenousBam", "inputBam",
            "bigWigEndogenous", "bigWigInput")
    .checkInfoFile(info_table, 6, colnames_vec)
    
    
    ## Adding paths to files
    
    if(isTRUE(all.equal(str_sub(bamPath, -1), "/")) || 
            isTRUE(all.equal(str_sub(bigWigPath, -1), "/")))
        stop("Paths to bam and bigWig files should not end by '/'.")
    
    info_table$endogenousBam <- 
            paste(bamPath, info_table$endogenousBam, sep="/")
    info_table$exogenousBam <- paste(bamPath, info_table$exogenousBam, 
                                     sep="/")
    info_table$inputBam <- paste(bamPath, info_table$inputBam, sep="/")
    info_table$bigWigEndogenous <- 
            paste(bigWigPath, info_table$bigWigEndogenous, sep="/")
    info_table$bigWigInput <- 
            paste(bigWigPath, info_table$bigWigInput, sep="/")
    
    ## If only one input file is provided, the dataset is made of one object
    ## ChIPSeqSpikeDataset or ChIPSeqSpikeDatasetBoost. Otherwise it will be a
    ## list of the previously mentioned objects.
    
    if(isTRUE(all.equal(length(unique(info_table$inputBam)), 1))){
        
        if(!isTRUE(all.equal(length(unique(info_table$bigWigInput)), 1)))
            stop("The input bam and bigWig files do not correspond.")
        
        if(boost){
            if(.Platform$OS.type != 'windows') {
                ChIPSeqSpikeDatasetBoost(info_table$endogenousBam, 
                        info_table$exogenousBam, 
                        info_table$bigWigEndogenous, 
                        unique(info_table$bigWigInput), 
                        unique(info_table$inputBam), 
                        info_table$expName,
                        verbose)
            }else{
                stop("As of rtracklayer >= 1.37.6, BigWig is not ",
                        "supported on Windows.")
            }
        }else
            ChIPSeqSpikeDataset(info_table$endogenousBam, 
                    info_table$exogenousBam, 
                    info_table$bigWigEndogenous, 
                    unique(info_table$bigWigInput), 
                    unique(info_table$inputBam), 
                    info_table$expName)
    }else{
        
        list_dataset <- split(info_table, factor(info_table$inputBam, 
                                                levels = info_table$inputBam))
        names(list_dataset) <- paste0("dataset", 
                                      seq_len(length(list_dataset)))
        
        if(boost){
            if(.Platform$OS.type != 'windows') {
                ChIPSeqSpikeDatasetListBoost(list_dataset, verbose)
            }else{
                stop("As of rtracklayer >= 1.37.6, BigWig is not ",
                        "supported on Windows.")
            }
        }else
            ChIPSeqSpikeDatasetList(list_dataset, verbose)
    }
}


## Constructor of ChIPSeqSpikeDatasetListBoost


ChIPSeqSpikeDatasetListBoost <- function(dataset_list, verbose){
    
    if(.Platform$OS.type != 'windows') {
        ChIPSeqSpikeDatasetBoostCollection <- lapply(dataset_list, 
                function(dataset_table){
                    
                    return(
                            ChIPSeqSpikeDatasetBoost(
                                    dataset_table[, "endogenousBam"], 
                                    dataset_table[, "exogenousBam"], 
                                    dataset_table[, "bigWigEndogenous"],
                                    unique(dataset_table[, "bigWigInput"]), 
                                    unique(dataset_table[, "inputBam"]),
                                    dataset_table[, "expName"],
                                    verbose = verbose))
                })
        
        new("ChIPSeqSpikeDatasetListBoost", 
                datasetList = ChIPSeqSpikeDatasetBoostCollection)
    }else{
        stop("As of rtracklayer >= 1.37.6, BigWig is not ",
                "supported on Windows.")
    }
}


## Constructor of ChIPSeqSpikeDatasetList

ChIPSeqSpikeDatasetList <- function(dataset_list, verbose){
    
    ChIPSeqSpikeDatasetCollection <- lapply(dataset_list, 
            function(dataset_table){
                
                return(
                        ChIPSeqSpikeDataset(
                                dataset_table[, "endogenousBam"], 
                                dataset_table[, "exogenousBam"], 
                                dataset_table[, "bigWigEndogenous"],
                                unique(dataset_table[, "bigWigInput"]), 
                                unique(dataset_table[, "inputBam"]),
                                dataset_table[, "expName"]))
            })
    
    new("ChIPSeqSpikeDatasetList", 
            datasetList = ChIPSeqSpikeDatasetCollection)
}


## Constructor of ChIPSeqSpikeCore


ChIPSeqSpikeCore <- function(inputBamFile, inputBigWigFile, inputSF = 0, 
        inputNb = 0, SetArrayList = list(), matBindingList = list()){
    
    if(!(isTRUE(all.equal(length(inputBigWigFile), 1)) && 
                isTRUE(all.equal(length(inputBamFile),1))))
        stop("Only one bigWig and bam file should be given for the input", 
                " experiment.")
    
    if(!inherits(SetArrayList, "list"))
        stop("SetArrayList should be of type list.")
    
    if(!inherits(matBindingList, "list"))
        stop("matBindingList should be of type list.")
    
    new("ChIPSeqSpikeCore", inputBam = inputBamFile,
            inputBigWig = inputBigWigFile,
            inputScalingFactor = inputSF,
            inputCount = inputNb,
            plotSetArrayList = SetArrayList,
            matBindingValList = matBindingList)
    
}


## Constructor of ChIPSeqSpikeDataset which inherits from ChIPSeqSpikeCore and 
## which is a list of Experiment object.


.verifyDataset <- function(endogenousBam_vec, exogenousBam_vec, 
        bigWigFile_endogenous_vec, expnames){
    
    if(!identical(length(endogenousBam_vec), length(exogenousBam_vec)))
        stop("A corresponding exogenous bam is needed for each experiment.")
    
    if(!identical(length(endogenousBam_vec), 
            length(bigWigFile_endogenous_vec))) 
        stop("A bigWig and bam file should be given for each experiment.")
    
    if(!identical(length(expnames), length(endogenousBam_vec)))
        stop("One name should be provided per experiment.")
}


ChIPSeqSpikeDataset <- function(endogenousBam_vec, exogenousBam_vec, 
        bigWigFile_endogenous_vec, inputBigWigFile, inputBamFile, expnames,
        inputSF = 0, inputNb = 0, SetArrayList = list(), 
        matBindingList = list()){
    
    .verifyDataset(endogenousBam_vec, exogenousBam_vec, 
            bigWigFile_endogenous_vec, expnames)
        
    experimentCollection <- mapply(function(endoB, exoB, target, name){
                
                return(Experiment(endoB, exoB, target, name))
                
            }, endogenousBam_vec, exogenousBam_vec, 
            bigWigFile_endogenous_vec, expnames)
    
    names(experimentCollection) <- expnames
    
    new("ChIPSeqSpikeDataset", 
            ChIPSeqSpikeCore(inputBamFile, inputBigWigFile, inputSF, inputNb, 
                    SetArrayList, matBindingList),
            experimentList = experimentCollection)
    
}


## Constructor of ChIPSeqSpikeDatasetBoost which inherits from 
## ChIPSeqSpikeDataset and is a list of ExperimentLoaded objects.

ChIPSeqSpikeDatasetBoost <- function(endogenousBam_vec, exogenousBam_vec, 
        bigWigFile_endogenous_vec, inputBigWigFile, inputBamFile, expnames,
        inputSF = 0, inputNb = 0, SetArrayList = list(), 
        matBindingList = list(), verbose = TRUE){
    
    if(.Platform$OS.type != 'windows') {
        .verifyDataset(endogenousBam_vec, exogenousBam_vec, 
                bigWigFile_endogenous_vec, expnames)
        
        if(verbose)
            message("Reading input bigWig file.")
        
        loaded_input_bigWig <- import(inputBigWigFile, format="BigWig")
        
        loaded_exp_list <- mapply(function(endoB, exoB, target, name){
                    
                    return(ExperimentLoaded(endoB, exoB, target, name, 
                                    verbose = verbose))
                    
                }, endogenousBam_vec, exogenousBam_vec, 
                bigWigFile_endogenous_vec, expnames)
        
        names(loaded_exp_list) <- expnames
        
        new("ChIPSeqSpikeDatasetBoost", 
                ChIPSeqSpikeCore(inputBamFile, inputBigWigFile, inputSF, inputNb, 
                        SetArrayList, matBindingList),
                experimentListLoaded = loaded_exp_list,
                inputBigWigLoaded = loaded_input_bigWig)
    }else{
        stop("As of rtracklayer >= 1.37.6, BigWig is not supported on ",
                "Windows.")
    }
}


## Constructor of Experiment objects


Experiment <- function(endogenousBamFilePath, exogenousBamFilePath, 
        bigWigFilePath, name, endoScalingFactor = 0, exoScalingFactor = 0, 
        endoNb = 0, exoNb = 0){
    
    if(!is.character(endogenousBamFilePath)){
        stop("endogenousBamFilePath should be a string.")
    }
    
    if(!is.character(exogenousBamFilePath)){
        stop("exogenousBamFilePath should be a string.")
    }
    
    if(!is.character(bigWigFilePath)){
        stop("bigWigFilePath should be a string.")
    }
    
    
    if(!is.numeric(name) && !is.character(name)){
        stop("name should be an alphanumeric.")
    }
    
    if(!(is.numeric(endoScalingFactor) && is.numeric(exoScalingFactor)
         && is.numeric(endoNb) && is.numeric(exoNb))){
        stop("Scaling factors and counts should be numeric.")
    }
    
    new("Experiment", 
            endogenousBam = endogenousBamFilePath,
            exogenousBam = exogenousBamFilePath,
            bigWigFile = bigWigFilePath,
            expName = name,
            endogenousScalingFactor = endoScalingFactor,
            exogenousScalingFactor = exoScalingFactor,
            endoCount = endoNb,
            exoCount = exoNb)
}


## Constructor of ExperimentLoaded objects


ExperimentLoaded <- function(endogenousBamFilePath, exogenousBamFilePath, 
        bigWigFilePath, name, endoScalingFactor = 0, exoScalingFactor = 0, 
        endoNb = 0, exoNb = 0, verbose = TRUE){
    
    if(.Platform$OS.type != 'windows') {
        if(verbose)
            message("Reading ", name)
        
        loaded_bigWig <- import(bigWigFilePath, format="BigWig")
        
        new("ExperimentLoaded",
                Experiment(endogenousBamFilePath, exogenousBamFilePath, 
                     bigWigFilePath, name, endoScalingFactor, exoScalingFactor,
                        endoNb, exoNb),
                loadedBigWigFile = loaded_bigWig)
    }else{
        stop("As of rtracklayer >= 1.37.6, BigWig is not ",
                "supported on Windows.")
    }
}
