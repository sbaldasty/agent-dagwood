library(dagwood)
library(ggdag)

DAG.root <- "Chocolate -> Alzheimers
Chocolate <- Education -> Alzheimers
Chocolate -> CV
CV -> Alzheimers"

exposure <- "Chocolate"
outcome <- "Alzheimers"

result <- dagwood(DAG.root, exposure, outcome)

branch.DAGs <- result$DAGs.branch
ggdag(branch.DAGs$DAG.branch.candidate[1]) + theme_dag()
