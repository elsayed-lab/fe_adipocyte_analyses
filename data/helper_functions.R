hline <- function(y = 0, color = "black") {
    list(
        type = "line",
        x0 = 0,
        x1 = 1,
        xref = "paper",
        y0 = y,
        y1 = y,
        line = list(color = color)
    )
}

vline <- function(x = 0, color = "green") {
    list(
        type = "line",
        y0 = 0,
        y1 = 1,
        yref = "paper",
        x0 = x,
        x1 = x,
        line = list(color = color)
    )
}

volc_plot <- function(res_tbl, title = "", subtitle = "", 
                      type = "ggplot", tbl = "DESeq", shape = NULL, 
                      size = 4, gene_name_col = "external_gene_name", 
                      colors = NULL) {
    if(tbl == "DESeq"){
        if(!("Significance" %in% names(res_tbl))){
            res_tbl <- set_sig(res_tbl)
        }
        if(type == "plotly") {
            Significance <- res_tbl[["Significance"]]
            fig <- plot_ly(res_tbl, x = ~ log2FoldChange, y = ~ -log10(padj), color = Significance, 
                           text = ~paste('Gene: ', res_tbl[["external_gene_name"]]))
            fig <- fig %>% add_markers()
            p <- fig %>% layout(scene = list(xaxis = list(title = "log2(FC)")),
                                yaxis = list(title = "-log10(p-value)"))
        } else {
            if(is.null(shape)) {
            #create ggplot
            p <- ggplot(res_tbl, aes(x = log2FoldChange, y = -log10(padj), label = gene_name_col)) + 
                geom_point(aes(colour = Significance), size = size) + 
                geom_vline(xintercept = c(-1,1)) +
                geom_hline(yintercept = -log10(.05)) +
                theme_classic(base_size = 20) +
                xlab("log2(FC)") +
                ylab("-log10(p-value)") +
                ggtitle(title, subtitle = subtitle) +
                theme(legend.position="bottom") +
                scale_color_manual(values=c( "#F8766D", "#00BFC4", 'Grey')) 
            } else {
                Shape <- res_tbl[[shape]]
                p <- ggplot(res_tbl, aes(x = log2FoldChange, y = -log10(padj), label = gene_name_col)) + 
                    geom_point(aes(colour = Significance, shape = Shape), size = size) + 
                    geom_vline(xintercept = c(-1,1)) +
                    geom_hline(yintercept = -log10(.05)) +
                    theme_classic(base_size = 20) +
                    xlab("log2(FC)") +
                    ylab("-log10(p-value)") +
                    ggtitle(title, subtitle = subtitle) +
                    theme(legend.position="bottom") +
                    scale_color_manual(values=c( "#F8766D", "#00BFC4", 'Grey'))                
                
            }
        }
    } else if (tbl == "limma") {
        if(!("Significance" %in% names(res_tbl))){
            res_tbl <- set_sig(res_tbl)
        }
        if(type == "plotly") {
            Significance <- res_tbl[["Significance"]]
            fig <- plot_ly(res_tbl, x = ~ logFC, y = ~ -log10(adj.P.Val), color = Significance, 
                           text = ~paste('Gene: ', res_tbl[[gene_name_col]]))
            fig <- fig %>% add_markers()
            p <- fig %>% layout(scene = list(xaxis = list(title = "log2(FC)")),
                                yaxis = list(title = "-log10(p-value)"))
        } else {
            if(is.null(shape)) {
            #create ggplot
            p <- ggplot(res_tbl, aes(x = logFC, y = -log10(adj.P.Val), label = gene_name_col)) + 
                geom_point(aes(colour = Significance), size = size) + 
                geom_vline(xintercept = c(-1,1)) +
                geom_hline(yintercept = -log10(.05)) +
                theme_classic(base_size = 20) +
                xlab("log2(FC)") +
                ylab("-log10(p-value)") +
                ggtitle(title, subtitle = subtitle) +
                theme(legend.position="bottom") +
                scale_color_manual(values=c( "#F8766D", "#00BFC4", 'Grey')) 
            } else {
                Shape <- res_tbl[[shape]]
                p <- ggplot(res_tbl, aes(x = logFC, y = -log10(adj.P.Val), label = gene_name_col)) + 
                    geom_point(aes(colour = Significance, shape = Shape), size = size) + 
                    geom_vline(xintercept = c(-1,1)) +
                    geom_hline(yintercept = -log10(.05)) +
                    theme_classic(base_size = 20) +
                    xlab("log2(FC)") +
                    ylab("-log10(p-value)") +
                    ggtitle(title, subtitle = subtitle) +
                    theme(legend.position="bottom") +
                    scale_color_manual(values=c( "#F8766D", "#00BFC4", 'Grey')) 
                
            }
        }
    } 
  if (!is.null(colors)) {
    p <- p + scale_color_manual(values = colors)
  }
    return(p)
}

set_sig <- function(DEseq_tbl, factors = NULL) {
    #set significance for plotting colors
    if (is.null(factors)) {
        DEseq_tbl$Significance <- NA
        DEseq_tbl[DEseq_tbl$log2FoldChange >= 1  & DEseq_tbl$padj <= .05, ][["Significance"]] <- "Disease \nUpregulated"
        DEseq_tbl[DEseq_tbl$log2FoldChange <= -1  & DEseq_tbl$padj <= .05, ][["Significance"]] <- "Disease \nDownregulated"
        DEseq_tbl[abs(DEseq_tbl$log2FoldChange) < 1 | DEseq_tbl$padj > .05, "Significance"] <- "Not \nEnriched"
        DEseq_tbl$Significance <- factor(DEseq_tbl$Significance, levels = c("Disease \nUpregulated", "Disease \nDownregulated",  "Not \nEnriched"))
    } else {
        DEseq_tbl$Significance <- NA
        DEseq_tbl[DEseq_tbl$log2FoldChange >= 1  & DEseq_tbl$padj <= .05, ][["Significance"]] <- factors[1]
        DEseq_tbl[DEseq_tbl$log2FoldChange <= -1  & DEseq_tbl$padj <= .05, ][["Significance"]] <- factors[2]
        DEseq_tbl[abs(DEseq_tbl$log2FoldChange) < 1 | DEseq_tbl$padj > .05, "Significance"] <- "Not \nEnriched"
        DEseq_tbl$Significance <- factor(DEseq_tbl$Significance, levels = c(factors,  "Not \nEnriched"))        
    }
    return(DEseq_tbl)
}

set_sig_limma <- function(limma_tbl, factors = NULL) {
    if (is.null(factors)) {
        #set significance for plotting colors
        limma_tbl$Significance <- NA
        limma_tbl[abs(limma_tbl$logFC) < 1 | limma_tbl$adj.P.Val > .05, "Significance"] <- "Not \nEnriched"
        limma_tbl[limma_tbl$logFC >= 1  & limma_tbl$adj.P.Val <= .05, ][["Significance"]] <- "Disease \nUpregulated"
        limma_tbl[limma_tbl$logFC <= -1  & limma_tbl$adj.P.Val <= .05, ][["Significance"]] <- "Disease \nDownregulated"
        limma_tbl$Significance <- factor(limma_tbl$Significance, levels = c("Disease \nUpregulated", "Disease \nDownregulated",  "Not \nEnriched"))
    } else {
        limma_tbl$Significance <- NA
        limma_tbl[abs(limma_tbl$logFC) < 1 | limma_tbl$adj.P.Val > .05, "Significance"] <- "Not \nEnriched"
        if(nrow(limma_tbl[limma_tbl$logFC >= 1  & limma_tbl$adj.P.Val <= .05, ]) != 0) { 
          limma_tbl[limma_tbl$logFC >= 1  & limma_tbl$adj.P.Val <= .05, ][["Significance"]] <- factors[1] 
          }
        if (nrow(limma_tbl[limma_tbl$logFC <= -1  & limma_tbl$adj.P.Val <= .05, ]) != 0) {
          limma_tbl[limma_tbl$logFC <= -1  & limma_tbl$adj.P.Val <= .05, ][["Significance"]] <- factors[2]
        }
        limma_tbl$Significance <- factor(limma_tbl$Significance, levels = c(factors,  "Not \nEnriched"))
    }
    return(limma_tbl)
}


reorder_cormat <- function(cormat) {
    dd <- as.dist((1-cormat)/2)
    hc <- hclust(dd)
    cormat <- cormat[hc$order, hc$order]
    return(cormat)
}

data_summary <- function(data, varname, groupnames){
    summary_func <- function(x, col){
        c(mean = mean(x[[col]], na.rm=TRUE),
          sd = sd(x[[col]], na.rm=TRUE))
    }
    data_sum<-plyr::ddply(data, groupnames, .fun=summary_func,
                          varname)
    #data_sum <- rename(data_sum, c("mean" = varname))
    return(data_sum)
}


plot_exprs <- function(df, gene_oi, groupname) {
    df2 <- data_summary(df, varname=gene_oi, 
                        groupnames=c("Disease"))
    colnames(df2) <- c("Disease", "gene", "sd")
    # Convert dose to a factor variable
    df2$Disease <- as.factor(df2$Disease)
    
    p <- ggplot(df2, aes(x = Disease, y = gene, fill = Disease)) + 
        geom_violin() +
        geom_point(stat="identity", color = "black") +
        scale_fill_manual(values=c('#BF382A', '#0C4B8E')) +
        geom_errorbar(aes(ymin=gene, 
                          ymax=gene+sd), 
                      width=.2,
                      position=position_dodge(.9)) +
        ylab(paste0(gene_oi, " Expression"))
    return(p)
}




