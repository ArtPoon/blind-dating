library(seqinr)

args.all <- commandArgs(trailingOnly = F)

if (any(grep("--file=", args.all))) {
	source.dir <- dirname(sub("--file=", "", args.all[grep("--file=", args.all)]))
} else {
	file.arg <- F

	for (i in 1:length(args.all)) {
		if (file.arg) {
			source.dir <- dirname(args.all[i])
		
			break
		}
		
		file.arg <- args.all[i] == '-f'
	}
}

source(file.path(source.dir, 'read.info.R'), chdir=T)

get.time.points <- function(i) {
	s <- sampler[, i]
	
	which(dates %in% s)
}

args <- commandArgs(trailingOnly = T)

FASTA_FILE <- args[1]
INFO_FILE <- args[2]
SUFFIX <- args[3]
METHOD <- as.integer(args[4]) # 0: N RNA time points 1: all but 1 time point, 2: 2 RNA time points, -2: all but 2 time points
REPS <- as.integer(args[5]) # number of replicates generated for method 0
TIME_POINTS <- as.integer(args[6]) # number of time points, N, for method 0
SEED <- as.integer(args[7])

cat("Reading...\n")

fasta <- read.fasta(FASTA_FILE)
fasta.names <- names(fasta)
info <- read.info(INFO_FILE, fasta.names)
types <- info$CENSORED

ref <- which("REFERENCE" == fasta.names)
if (length(ref) > 0)
	types[ref] <- 1

fasta.rna <- fasta[which(types == 0)]
fasta.dna <- fasta[which(types == 1)]
fasta.names <- names(fasta.rna)

dates <- info$COLDATE[types == 0]
time.points <- sort(unique(dates))
n.points <- length(time.points)

method <- if (METHOD == 0) {
	full.sampler <- combn(time.points, TIME_POINTS)
	set.seed(SEED)
	sampler <- full.sampler[, sample(ncol(full.sampler), REPS)] 
	reps <- REPS

	get.time.points
} else if (METHOD == 1) {
	sampler <- combn(time.points, n.points - 1)
	reps <- ncol(sampler)
	
	get.time.points
} else if (METHOD == 2) {
	sampler <- combn(time.points, 2)
	reps <- ncol(sampler)
	
	get.time.points
} else {
	sampler <- combn(time.points, n.points - 2)
	reps <- ncol(sampler)
	
	get.time.points
}

cat("Filtering...\n")
filters <- lapply(1:reps, method)
cat("Writing...\n")
suppress <- lapply(1:reps, function(i) {
	f <- c(fasta.rna[filters[[i]]], fasta.dna)
	write.fasta(f, names(f), paste0(SUFFIX, i, ".fasta"))
})


quit()


