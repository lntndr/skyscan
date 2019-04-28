# skyscan

## Problemi noti

- **Il programma non legge direttamente i file creati da Labview ma una loro versione CSV-like generata da filecleaner.sh su Linux o da filecleaner.ps1 su Windows che elimina le righe vuote, gli spazi bianchi e imposta , come separatore valori e . come separatore decimali.**
- I controlli di coerenza degli argomenti sono incompleti

## Da fare
-Permettere controllo risoluzione grafichini

## Riferimento
```
set=skyscan
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
- **silent_run=false**
	- Non mostra le figure quando prodotte.
- **export_png=false**
	- Esporta in una sottocartella *skyscan_png* i grafici in formato .png 
- **output_dir=''**
	- Permette di scegliere la cartella in cui viene creata la sottocartella *skyscan_png*. Se non specificato, è uguale a *custom_directory*, se anche questa non è specificata è, come al solito, la cartella dove si trova skyscan.m

```
int=skyskan(set)
```
esegue con i valori impostati in *set*. L'integrale viene restituito come una matrice in cui ogni riga corrisponde a un file analizzato e ogni elemento all'integrale su una riga del file delle misure.

## Scenari d'uso
Cambiando i valori da quelli di default sopra si può modificare il comportamento del programma in modo di renderlo utile in diversi contesti.
### Anteprima grezza raccolte dati
Per avere un'idea di massima di numerosi file si può configurare il programma in tal modo

```
>> agrd=skyscan;
	    recur_over_folder: 1
                     filename: ''
             custom_directory: '~/Documenti/raccolta190427'
                    make_plot: 1
                sample_module: 1
    dedicated_figure_per_file: 1
               enable_browser: 0
                   silent_run: 1
                   export_png: 1
                   output_dir: '~/Immagini/raccolta190427'
>> intg=skyscan(agrd);

```
In questo scenario il programma prenderà tutti i file di dati nella cartella ~/Documenti/Raccolta190427, li caricherà in RAM in una matrice 3D e ne calcolerà i grafici, non mostrandoli all'utente ma salvandoli in formato png risoluzione 473*390 nella cartella ~/Immagini/raccolta190427/skyscan_png . Il programma crea la cartella se non esistente ma *non* la aggiunge al PATH di MATLAB autonomamente perché rallenterebbe l'esecuzione del programma: conviene farlo a mano. Nel caso fosse utile il blocco di codice è presente e commentato nella funzione.

Si noti come le definizioni di cartelle si comportino a tutti gli effetti come un cd a partire dal percorso in cui si trova skyscan.m . Sarebbero validi, ma sconsigliati, percorsi relativi.

### Controllo di fino di un file

```
>>cff=skyscan
	    recur_over_folder: 0
                     filename: '190416_120451_USRP.txt'
             custom_directory: ''
                    make_plot: 1
                sample_module: 1
    dedicated_figure_per_file: 1
               enable_browser: 1
                   silent_run: 0
                   export_png: 0
                   output_dir: ''
>>intg=skyscan(cff)
```
In questo caso il programma legge il singolo file specificato in *filename* supponendo che si trovi nella stessa cartella di skyscan.m facendone il grafico e mostrandolo all'utente con legenda interattiva, permettendo di mostrare o nascondere le singole righe.

### Comparazione file su stessa figura
```
>>cfsf=skyscan
	    recur_over_folder: 1
                     filename: ''
             custom_directory: ''
                    make_plot: 1
                sample_module: 2
    dedicated_figure_per_file: 0
               enable_browser: 0
                   silent_run: 0
                   export_png: 0
                   output_dir: ''
>>intg=skyscan(cfsf)
```
In questo caso il programma elabora tutti i file di dati presenti nella cartella di skyscan.m e li mette in un unica figura non interattiva, assegnando un colore a ogni singolo file. Inoltre, per ridurre il tempo d'esecuzione, *sample_module* posto uguale a 2 fa in modo che il grafico contenga solo la metà dei punti. *sample_module* non influisce sul computo degli integrali.
