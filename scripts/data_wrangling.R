library(openxlsx)
library(tidyr)
library(dplyr)
library(networkD3)

# Import the connection data frame: a list of flows with intensity for each flow (link)
links <- read.xlsx(xlsxFile = '../data/data_wrangling.xlsx', sheet = 'data_wrangling_links')

# From these connections we create a node data frame: it lists every entity involved in the flow
nodes <- data.frame(name = unique(c(links$source, links$target)))

# Bring node description from the metadata sheet
metadata <- read.xlsx(xlsxFile = '../data/data_wrangling.xlsx', sheet = 'metadata')
target_obs <- metadata[ , c(3,6)]
nodes <- left_join(nodes, target_obs, by = c("name" = "node"))

# With networkD3, connections are provided as an id. So we need to reformat it
links$id_source <- match(links$source, nodes$name) - 1
links$id_target <- match(links$target, nodes$name) - 1

# Format labels for key nodes
nodes$name[1] <- c("DATA WRANGLING")
links$source[1:6] <- c("DATA WRANGLING")

# Make the Network
sn <- sankeyNetwork(Links = links, Nodes = nodes,
                    Source = "id_source", Target = "id_target", LinkGroup = "source",
                    Value = 'value', NodeID = "name",
                    sinksRight = FALSE, fontSize = 12, fontFamily = 'Helvetica')

# Add relevant information to the HTML tooltip
# (see https://stackoverflow.com/questions/45635970/displaying-edge-information-in-sankey-tooltip/45918897#45918897)

# Add obs back into the nodes data because sankeyNetwork strips it out
sn$x$nodes$obs <- replace_na(data = nodes$definition, replace = ' ')

# Use ".link" for links or ".node" for nodes and d.XXX where XXX is the value you want to use on the tooltip
sn <- htmlwidgets::onRender(
  sn,
  '
  function(el, x) {
  d3.selectAll(".node").select("title foreignObject body pre")
  .text(function(d) { return d.obs; });
  }
  '
)

saveNetwork(sn, 'data_wrangling.html', selfcontained = TRUE)
