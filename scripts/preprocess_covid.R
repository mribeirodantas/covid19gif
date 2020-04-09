# Os dados de COVID19 foram obtidos através do dashboard oficial do
# Ministério da Saúde em https://covid.saude.gov.br/
# Basta ir até o final da página e clicar em "Arquivo CSV"
# Um arquivo será baixado e é só jogar ele na pasta data. Vamos renomeá-lo
# para covid19.csv

setwd('/home/mribeirodantas/Dropbox/Analyses/GIFcasosSP/')


# Lendo dados de mortalidade de SP -------------------------------------

library(dplyr)
library(readr)
library(stringr)
library(purrr)

covid19 <- read_csv2('data/covid19.csv', locale = locale(encoding = 'latin1'))

# Preprocessando dados de COVID19 de SP -------------------------------

glimpse(covid19)
# Esse dataset já está mais limpinho

# Vamos manter apenas as colunas que nos interessam
# do estado de SP
covid19 %>%
 # Nosso interesse é em SP
 filter(sigla == 'SP') %>%
 # E novos óbitos diários
 select(date, obitosNovos) %>%
 # Portanto, não nos importa
 # quando não tinha óbito algum
 filter(obitosNovos != 0) -> covid19

# Quando eu gerei o GIF que estou ensinando a fazer aqui, ainda não tinha
# terminado o dia 8, portanto vou parar aqui também no dia 7.
slice(covid19, 1:(n()-1)) -> covid19

# Melhorar o nome das variáveis
colnames(covid19) <- c('data', 'n_obitos_dia')

write_csv2(covid19, 'scripts/outputs/covid19_preprocessado.csv')