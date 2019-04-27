# skyscan
## Problemi noti
- **Il programma non legge direttamente i file creati da Labview ma una loro versione CSV-like generata da filecleaner.sh che elimina le righe vuote, gli spazi bianchi e imposta , come separatore valori e . come separatore decimali.** Lo script bash non è eseguibile nativamente su Windows, ma solo attraverso espedienti come la riga bash installata con git, Cygwin o WSL.
## Guida rapida
```
set=skyskan
```
crea una struct *set* con al suo interno i valori predefiniti dei possibili parametri con cui si puo fare girare il programma. Nello specifico sono
- **recur_over_folder=true**
	- Il programma cerca per lavorarci tutti i file del tipo *_USRP.txt nella cartella. Salvo non venga ridefinita in *custom_folder* la cartella in cui cerca è la stessa di skyscan.m
- **filename=''**
	- Il programma lavora solo con il file presente nel parametro, che viene cercato nella cartella di skyscan.m o in *custom_folder* se definita
- **custom_directory=''**
	- Ridefinisce la cartella di lavoro del programma. Su Linux ho testato e funziona usare la tilde e.g. '~/prova/test', su Windows probabilmente serve il percorso completo 'C:/eccetera'
	
- **make_plot=true**
	- Il programma crea o meno i grafici.
- **sample_module=1**
	- Il programma mette nel grafico solo un punto ogni *sample_module* per ogni riga analizzata. Utile in caso di molti file.
- **dedicated_figure_per_file=true**
	-Se vero crea una figura per ogni file assegnando un colore a ogni riga del file, se falso crea un'unica figura per tutti i file assegnando un colore a ogni file.
- **enable_browser=false**
	- Apre il *plotbrowser* di MATLAB permettendo di selezionare, mostare e nascondere ogni presa dati in un grafico. Sconsigliato l'uso con prese dati particolarmente impegnative perché abbastanza lento.

```
skyskan(set)
```
esegue con i valori impostati in *set*. Non è necessario che *set* contenga tutti i campi in quanto il programma provvede a completare quelli mancanti con quelli di default sopra elencati. L'integrale viene restituito come una matrice in cui ogni riga corrisponde a un file analizzato e ogni elemento all'integrale su una riga del file delle misure.

