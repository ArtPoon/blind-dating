#!/usr/bin/Rscript

library(ggplot2)

pdf.options(family="Helvetica", fonts="Helvetica", width=7, height=7, colormodel='rgb')

my.theme <- theme(
	text=element_text(size=20),
	axis.text=element_text(size=15, colour='black'),
	legend.text=element_text(size=15),
	legend.position=0,
	axis.text.x=element_text(angle=90, vjust=0.5, hjust=1),
	legend.justification=c(0, 1),
	legend.spacing=unit(0, 'cm'),
	legend.margin=margin(0, 0, 0, 0, 'cm'),
	legend.key.size=unit(1.2, 'cm'),
	legend.key=element_rect(fill="#00000000", colour="#00000000"),
	legend.background=element_blank(),
	legend.box.background=element_blank(),
	panel.grid.major=element_blank(),
	panel.grid.minor=element_blank()
) 

my.theme2 <- theme(
 text=element_text(size=35),
 axis.text=element_text(size=30, colour='black'),
 legend.text=element_text(size=25),
 legend.position=c(.99, .99),
 legend.justification=c(1, 1),
 legend.spacing=unit(0, 'cm'),
 legend.box='horizontal',
 legend.margin=margin(0.01, 0.01, 0.01, 0.01, 'cm'),
 legend.key.size=unit(1.2, 'cm'),
 legend.key=element_rect(fill="#00000000", colour="#00000000"),
 legend.background=element_blank(),
 legend.box.background=element_blank(),
 panel.grid.major=element_blank(),
 panel.grid.minor=element_blank()
)

concord <- function(x, y) {
	mu.x <- sum(x) / length(x)
	mu.y <- sum(y) / length(y)
	s.x <- sum((x - mu.x)^2) / length(x) 
	s.y <-  sum((y - mu.y)^2) / length(y)
	s.xy <- sum((x - mu.x) * (y - mu.y)) / length(y)
	
	2 * s.xy / (s.x + s.y + (mu.x - mu.y)^2)
}

read.csv.2 <- function(x) if (file.exists(x)) read.csv(x) else NA

my.theme.hist <- theme(
text=element_text(size=35),
axis.text=element_text(size=30, colour='black'),
axis.text.x=element_text(angle=90, hjust=1, vjust=0.5, size=20),
legend.text=element_text(size=30),
legend.title=element_text(size=30),
legend.position=c(.98, .98),
legend.justification=c(1, 1),
legend.spacing=unit(0, 'cm'),
legend.margin=margin(0, 0, 0, 0, 'cm'),
legend.key.size=unit(1.2, 'cm'),
legend.background=element_blank(),
legend.box.background=element_blank(),
panel.grid.major=element_blank(),
panel.grid.minor=element_blank()
)

pdf.options(family="Helvetica", fonts="Helvetica", width=7, height=7, colormodel='rgb')

files <- dir("info", "[0-9].cens.csv")

data.files.rtt <- paste0("stats/", gsub(".cens.csv", ".data.csv", files))
stats.files.rtt <- paste0("stats/", gsub(".cens.csv", ".stats.csv", files))
data.rtt <- lapply(data.files.rtt, read.csv.2)
stats.rtt <- do.call(rbind, lapply(stats.files.rtt, read.csv.2))

good.rtt <- with(stats.rtt, !is.na(Model.Fit) & Model.Fit == 1)
data.rtt <- data.rtt[good.rtt]

data.rtt <- lapply(data.rtt, function(x) {x$Scaled.Difference <- x$Date.Difference / with(subset(x, Censored ==0), max(Collection.Date) - min(x$Collection.Date)); subset(x, x$Censored == 1)})

g <- ggplot() + theme_bw() + my.theme2

for (x in data.rtt[1:100]) {
	g <- g + geom_density(aes(x=Scaled.Difference), data=x, fill="black", alpha=1/100, color="#00000000")
}

pdf("sim.density.rtt.pdf")
g + geom_vline(xintercept=0, linetype='dashed', size=1, colour='black') + scale_x_continuous(name="Scaled Date Difference", limits=c(-1.6, 1.6)) + scale_y_continuous(name="Density", limits=c(0, 30))
dev.off()

data.files.ogr <- paste0("stats/", gsub(".cens.csv", "-with_ref.data.csv", files))
stats.files.ogr <- paste0("stats/", gsub(".cens.csv", "-with_ref.stats.csv", files))
data.ogr <- lapply(data.files.ogr, read.csv.2)
stats.ogr <- do.call(rbind, lapply(stats.files.ogr, read.csv.2))

good.ogr <- with(stats.ogr, !is.na(Model.Fit) & Model.Fit == 1)
data.ogr <- data.ogr[good.ogr]

data.ogr <- lapply(data.ogr, function(x) {x$Scaled.Difference <- x$Date.Difference / (max(x$Collection.Date) - min(x$Collection.Date)); subset(x, x$Censored == 1)})

g <- ggplot() + theme_bw() + my.theme2

for (x in data.ogr[1:100]) {
	g <- g + geom_density(aes(x=Scaled.Difference), data=x, fill="#9966CC", alpha=1/100, color="#00000000")
}

pdf("sim.density.ogr.pdf")
g + scale_x_continuous(name="Scaled Date Difference", limits=c(-1, 1)) + scale_y_continuous(name="Density", limits=c(0, 30))
dev.off()

data.rtt <- lapply(data.files.rtt, read.csv.2)
data.rtt <- data.rtt[good.ogr & good.rtt]
data.ogr <- lapply(data.files.ogr, read.csv.2)
data.ogr <- data.ogr[good.ogr & good.rtt]

data.all <- do.call(rbind, lapply(1:length(data.rtt), function(i) cbind(Patient=stats.rtt[good.ogr & good.rtt, "Patient"][i], merge(data.rtt[[i]], data.ogr[[i]], by=c("ID", "Type", "Censored", "Collection.Date"), suffixes=c(".rtt", ".ogr")))))
data.all <- subset(data.all, Censored == 1)

pdf("sim.comp.pdf")
ggplot(data.all) + geom_abline() + geom_point(aes(x=Estimated.Date.rtt / 365.25, y=Estimated.Date.ogr / 365.25, colour=as.numeric(gsub(".+_", "", Patient))), alpha=0.1, show.legend=F) + scale_colour_gradient2(name="", low='red', high='blue', mid='green') + scale_x_continuous(name="Estimated Date RTT (years since simulation start)", limits=c(-1, 20)) + scale_y_continuous(name="Estimated Date OGR (years since simulation start)", limits=c(-1, 20)) + theme_bw() + my.theme
dev.off()

con.stats <- sapply(unique(data.all$Patient), function(x) with(subset(data.all, Patient == x), concord(Estimated.Date.rtt, Estimated.Date.ogr)))

pdf("sim.conc.pdf")
ggplot(data.frame(con=con.stats)) + geom_histogram(aes(x=con), breaks=seq(0, 1, length.out=21)) + theme_bw() + my.theme2 + scale_y_continuous(name="Frequency")
dev.off()

cat("Concordance:\n")
cat("Total: ", with(data.all, concord(Estimated.Date.rtt, Estimated.Date.ogr)), "\n", sep="")
