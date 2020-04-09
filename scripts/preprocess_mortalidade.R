# Os dados de mortalidade foram obtidos através do Tabnet do DATASUS.
# A base de dados é o Sistema de Informacões de Mortalidade (SIM).
# O link abaixo leva direto para os dados de São Paulo
# http://tabnet.datasus.gov.br/cgi/deftohtm.exe?sim/cnv/obt10SP.def
# Escolhi na linha: 'Causa CID-BR-10'
#            Coluna: 'Mês do Óbito'
#            Conteúdo: 'Óbitos por ocorrência'
#            Período: '2018'
# Clica em mostrar, e ao final da nova página gerada clica em COPIA COMO .CSV
# Vai baixar um arquivo com uma hash como nome. Aqui foi A133322193_52_24_15.csv
# Coloca na pasta data e vamos renomear o arquivo para mortalidade.csv

setwd('/home/mribeirodantas/Dropbox/Analyses/GIFcasosSP/')


# Lendo dados de mortalidade de SP -------------------------------------

library(dplyr)
library(readr)
library(stringr)
library(purrr)

mortalidade_sp <- read_lines('data/mortalidade.csv') %>%
 head(n = -10) %>%
 paste(collapse = '\n') %>%
 read_csv2(skip = 3, locale = locale(encoding = 'latin1'))


# Preprocessando dados de mortalidade de SP -------------------------------

glimpse(mortalidade_sp)

# Limpar começo do nome das doenças
mortalidade_sp %>%
 select(`Causa - CID-BR-10`) %>%
 pull %>%
 str_replace('^\\.*\\s', '') %>%
 str_replace('^[0-9]*[\\-]?[0-9]*[\\.]?[0-9]* ',  '') -> mortalidade_sp$`Causa - CID-BR-10`

# Você pode achar que sem os números perderemos o controle dos grupos de
# doencas, mas segue sendo possível identificá-los porque estão com o nome
# todo em letra maíscula.

# Lista com o nome de doenças de interesse
doencas_interesse = c('Tuberculose', 'Doenças virais',
                      'Neopl malig da traquéia,brônquios e pulmões',
                      'Neoplasia maligna da mama',
                      'Leucemia', 'Diabetes mellitus', 'Desnutrição',
                      'Doença de Alzheimer', 'Infarto agudo do miocárdio',
                      'Influenza (gripe)', 'Pneumonia', 'Fibrose e cirrose do fígado',
                      'CAUSAS EXTERNAS DE MORBIDADE E MORTALIDADE')
# Eu vou juntar acidentes, quedas,

# Vamos ter certeza que os nomes estão escritos corretamente
all(doencas_interesse %in% mortalidade_sp$`Causa - CID-BR-10`)

# Meses de interesse
# Como iremos analisar apenas dados de COVID de Março e Abril,
# é mais indicado tirarmos a média diária dessas causas utilizando
# Março e Abril para tentar corrigir alguma possível sazionalidade.
meses_interesse = c('Março', 'Abril')
# Filtrar meses e doencas de interesse
mortalidade_sp <- mortalidade_sp %>%
 select(c(`Causa - CID-BR-10`, all_of(meses_interesse))) %>%
 filter(`Causa - CID-BR-10` %in% doencas_interesse)

# Vamos renomear as colunas e declarar os datatypes
colnames(mortalidade_sp) <- c('causa', 'Março', 'Abril')
mortalidade_sp$Março <- as.numeric(mortalidade_sp$Março)
mortalidade_sp$Abril <- as.numeric(mortalidade_sp$Abril)

# Vamos criar a coluna média diária
mortalidade_sp <- mortalidade_sp %>%
 mutate(media_diaria = rowSums(.[2:3])/61)

rm(doencas_interesse, meses_interesse)
write_csv2(mortalidade_sp, 'scripts/outputs/mortalidade_preprocessada.csv')
