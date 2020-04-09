setwd('/home/mribeirodantas/Dropbox/Analyses/GIFcasosSP/')

library(dplyr)
library(readr)
library(tidyr)

# Lê arquivos pré-processados ---------------------------------------------

covid <- read_csv2(file = 'scripts/outputs/covid19_preprocessado.csv')
mortalidade <- read_csv2(file = 'scripts/outputs/mortalidade_preprocessada.csv')


# Vamos montar o dataframe que será lido para gerar o gráfico -------------

mortalidade <- mortalidade %>%
 select(causa, media_diaria)

# Vamos repetir os dados de mortalidade para cada uma das datas que temos
# dados de COVID19 em SP
mortalidade %>% expand(covid$data, mortalidade) -> df
df$`covid$data` <- factor(df$`covid$data`, levels=unique(covid$data))
colnames(df) <- c('data', 'causa', 'media_diaria')

# Vamos alterar o df covid para o padrão de mortalidade
covid <- cbind(covid, causa = rep('COVID19', nrow(covid)))
colnames(covid) <- c('data', 'media_diaria', 'causa')
df <- rbind(df, covid[c(1,3,2)])

# A barra do COVID19 será vermelha e a dos demais cinza, para
# facilitar a visualização no gráfico
df$color <- ifelse(df$causa == 'COVID19', 'red', 'gray50')

df_formatted <- df %>%
 group_by(data) %>%
 # Ordenando causas por número de óbitos
 mutate(rank = rank(-media_diaria),
        Value_rel = media_diaria/media_diaria[rank==1],
        Value_lbl = paste0(" ",round(media_diaria))) %>%
 group_by(causa) %>%
 filter(rank <=15) %>%
 ungroup()

# Algumas causas ficaram com o nome muito longo e isso
# vai afetar a visualização. Vamos encurtá-los ou adicionar
# quebras de linha!
df_formatted %>%
 mutate(causa = case_when(causa == 'CAUSAS EXTERNAS DE MORBIDADE E MORTALIDADE' ~ 'Acidentes/Agressões\netc',
                          causa == 'Neopl malig da traquéia,brônquios e pulmões' ~ '\nCancer Traq/Bronq\n/Pulmão',
                          causa == 'Fibrose e cirrose do fígado' ~ 'Fibrose/Cirrose',
                          causa == 'Doença de Alzheimer' ~ 'Alzheimer',
                          causa == 'Infarto agudo do miocárdio' ~ 'Infarto Miocárdio',
                          causa == 'Neoplasia maligna da mama' ~ 'Cancer Mama',
                          TRUE ~ causa
                          )
) -> df_formatted



# Vamos preparar o gráfico agora ------------------------------------------

library(ggplot2)
library(gganimate)

staticplot = ggplot(df_formatted, aes(rank, group = causa,
                                      fill = color)) +
 geom_tile(aes(y = media_diaria/2,
               height = media_diaria,
               width = 0.9), alpha = 0.8, color = NA) +
 # geom_text(aes(y = 0, label = paste(gsub(' ', '\n', causa), " ")), vjust = 0.2, hjust = 1) +
 geom_text(aes(y = 0, label = causa), vjust = 0.2, hjust = 1) +
 geom_text(aes(y=media_diaria,label = Value_lbl, hjust=0)) +
 coord_flip(clip = "off", expand = FALSE) +
 scale_y_continuous(labels = scales::comma) +
 scale_fill_identity() +
 scale_x_reverse() +
 guides(color = FALSE, fill = FALSE) +
 theme(axis.line=element_blank(),
       axis.text.x=element_blank(),
       axis.text.y=element_blank(),
       axis.ticks=element_blank(),
       axis.title.x=element_blank(),
       axis.title.y=element_blank(),
       legend.position="none",
       panel.background=element_blank(),
       panel.border=element_blank(),
       panel.grid.major=element_blank(),
       panel.grid.minor=element_blank(),
       panel.grid.major.x = element_line( size=.1, color="grey" ),
       panel.grid.minor.x = element_line( size=.1, color="grey" ),
       plot.title=element_text(size=25, hjust=0.5, face="bold", vjust=-1),
       plot.subtitle=element_text(size=18, hjust=0.5, face="italic"),
       plot.caption =element_text(size=12, hjust=0.5, face="italic"),
       plot.background=element_blank(),
       plot.margin = margin(2,2, 2, 4, "cm"))


anim = staticplot + transition_states(data, transition_length = 21, state_length = 1, wrap=FALSE) +
 view_follow(fixed_x = TRUE)  +
 annotate(geom="text", x=10, y=51, label="http://mribeirodantas.xyz/blog (Ribeiro-Dantas, MC. 2020)",
          fontface='italic') +
 labs(title = 'COVID19 vs outras causas de morte em São Paulo por dia\n\n',
      subtitle  =  "\nNúmero de óbitos em {closest_state}",
      caption  = "Para COVID19, é o número de óbitos na data informada. Para as demais, média diária com base em Março e Abril (SIM, 2018)")

animate(anim, fps = 20, duration = 45, width = 900, height = 700, end_pause = 400)

anim_save('covid19_compar.gif', animation = last_animation(), path = 'scripts/outputs/')
