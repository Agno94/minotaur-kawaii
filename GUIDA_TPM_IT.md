# TPM2 UNLOCK

L'obiettivo di questo documento è aiutare a impostare lo sblocco automatico di un disco criptato.

Questo è possibile grazie ad un chip detto TPM v2 che registra un hash (in gergo si dice che il TPM "misura") di parte del codice eseguito in fase di avvio del PC e conversa dei segreti accessibili solo se gli hash misurati corrispondono.

La cifratura classica su linux viene implementato con un software chiamato LUKS. L'obiettivo di questo documento è che quando PC si avvia, se il sistema operativo non è stato manomesso, la partizione protetta da LUKS si sblocchi senza necessità che l'utente inserisca una password.

## Premesse

### 1. Versioni sistemi operativi

Ho abilitato successo lo sblocco con TPM2 su Ubuntu 23.10 e su POP!OS 22.04.

Diverse guide online prevedono software non disponibile nelle versioni correnti di Ubuntu, POP!OS e debian.
Ad esempio ho visto diverse guide che funzionano su sulle ultime versioni Fedora o anche su Debian beta/unstable ma sui sistemi sopra non funzionano.

Altro aspetto della cosa è che versioni diverse potrebbero richiedere leggeri cambiamenti.

Riporto anche le strade che ho escludo perché magari in futuro (magari con debian 13 o con ubuntu 24.04 o 26.04) diventeranno disponibili e magari saranno una di essa sarà una soluzione più semplice di quella presentata in questa guida.

##### Strade esclude

1. Lo sbloccaggio automatico della partizione LUKS con tpm2 non è possibile perché la versione di `cryptsetup` e script associati presenti nell'initramfs delle distro Ubuntu e POP!OS non funzionavano. È quindi necessario salvare nel TPM un payload casuale e usarlo come password secondaria per la partizione LUKS.
2. Usare `systemd-cryptenroll` non è possibile perché richiedere il punto 1.
3. C'è un software chiamato `clevis` che ho escluso per toccare il meno possibile le istallazione di Ubuntu e POP!OS
4. Per quanto riguarda la UKI (vedi sotto) ho escluso `ukify` di `systemd` perché manca delle versioni attuali di Ubuntu e POP!OS
5. Per Secure Boot i software `sbctl` consigliato dalla guida di ArchLinux non è presente nei repository. Ho preferito evitarlo quindi.

### 2. Sicurezza

Perché il sistema sia *sicuro* ma comunque *comodo* da usare ho scelto di:
- impostare una password di amministratore nel BIOS
- abilitare SecureBoot
- utilizzare una Unified Kernel Image (UKI, vedo dopo)

Con **sicuro** intendo che il segreto salvato nel TPM non possa essere recuperato da 
qualcuno malintenzionato che venisse in possesso nel computer
(che potrebbe, a questo punto, decifrare il disco e leggere i file).

Con **comodo** intendo che non serva entrare con password ed reimpostare il segreto nel TPM ad ogni aggiornamento del kernel o dell'initrd.
Credo sarà comunque necessario sbloccare il disco con password e reimpostare il segreto nel TPM in caso
di aggiornamento del firmware/BIOS nel PC (informazione non verificata) o in caso di cambino alcune impostazioni nel BIOS (casi rari quindi).

**Com'è possibile che il segreto del TPM non sia sicuro?**

L'avvio di un sistema linux richiede 3 pezzi princiali:
1. un'immagine di kernel
2. una linea di comando per il kernel
3. un disco iniziale ram (detto initramdisk, initrd o initramfs) che contiene i moduli per l'hardware e le istruzioni per montare la partizione di root ed avviare il sistema operativo

I problemi di sicurezza sono due:
- il kernel fa misurare solo se stesso dal TPM
- lo sblocco della partizione luks che contiene il sistema avviene grazie agli script contenuti dell'initrd

È quindi possibile che un malintenzionato modifichi l'initrd per scoprire la password di cifratura e, dato che l'initrd non viene misurato dal TPM.

> ASPETTO NON APPROFONDITO  
> Forse è possibile associare il segreto anche all'hash di una UKI (sicuramente PCR4 e forse qualche PCR>7), e allora cambiando l'initrd il TPM comunque non fornirebbe il segreto. Ma non sono sicuro di questo! E sicuramente vorrebbe dire dover reimpostare il segreto ogni volta che si aggiorna kernel o initrd! Quindi, se anche fosse sicura come strada, non la trovo comoda!

**Qual è il piano per procedere?**

Utilizziamo una Unified Kernel Image ovvero un singolo file che contiene:
- un programma EFI (avviabile dal BIOS) che carica il kernel ed il resto
- il kernel
- la linea di commando per il kernel
- il suo initrd
- opzionali: altre cose come uno splash screen e altro che non ci interessa

Firmeremo questo singolo file con una chiave registrata nel BIOS in modo tale che grazie a SecureBoot non sia possibile avviare immagini con initrd manomesso.

La password al BIOS serve perché altrimenti anche secureboot può essere manomesso.

Quindi abbiamo i tre requisiti di cui sopra.

### 3. Partizione EFI ed avvio del PC

Una UKI è un eseguibile EFI che sostituisce il bootloader.

Dovrà trovarsi un una partizione FAT32 detta ESP (credo stia per EFI System Partition). È già presente in ogni installazione perché è qui che sono stati installati i bootloader (nel mio avevo caso `grub` per Ubuntu 23.10 e `systemd-boot` per POP!OS 22.04).

La ESP viene solitamente montata sul sistemi linux sul percorso `/boot/efi` e su POP!OS è necessario essere root anche solo per vederne il contenuto.

È possibile scegliere direttamente dai menù del bios quale sistema avviare selezionando un diverso eseguibile EFI.

Io ho comunque tenuto i bootloader presenti precedentemente come soluzione di backup se qualcosa non funziona.

Ovviamente se avvio questi bootloader dovrò sbloccare "a mano" (scrivendo la password) il disco perché il TPM2 non mi darà il segreto in quando il meccanismo di avvio è diverso.

Un problema però è che conviene che nella ESP ci sia abbastanza spazio per un paio di UKI, le quali possono pesare parecchio.

Quindi attenzione allo spazio libero. Potrebbe essere necessario anche ridimensionare le partizioni.

### 4. Essere pronti se qualcosa va male

Sebbene abbia testato questa cosa su due sistemi e due PC diversi può essere che qualcosa non vada.

Per questo come prima cosa abilitiamo il backup del vecchio initrd e poi anche quello della UKI.

Il caso di problemi di avvio conviene avviare il sistema dal vecchio file backupato e fermarsi per capire cosa non ha funzionato.

Attenzione anche a non generare più volte initrd e/o UKI: così si perderebbe anche il backup. Consiglio: conviene riavviare il PC dopo aver generato un nuovo initrd e/o UKI per vedere che tutto funzioni bene.

### 5. Lavorare con il BIOS

Sarà utile avere ben chiaro come accedere a:
1. Il setup del bios
2. Il menù di selezione del boot

Sarà anche necessario capire se e in che forma sarà possibile aggiungere dei certificati nostri personali a quelli usati per implementare SecureBoot.

Io ho visto molta variabilità nei due PC che ho usato. In particolare nel PC Dell anche i nomi delle cose erano diversi da quelli standard trovati online ed aggiungere i certificati è stato estremamenti difficile (forse per via di un bug del BIOS). Quindi preparatevi a vedere cose con nomi non per forza uguali a quelli di questa guida.

È inoltre utile anche capire se il menù di boot permette di eseguire solo una delle opzioni disponibili nel menù o anche di eseguire il eseguibile EFI arbitrario.

Da sistema avviato è possibile riavviare direttamente nel setup del bios con

```sh
systemctl reboot --firmware-setup
```

Mentre è possibile vedere le opzioni del menù di boot e gli eseguibili che avviano con

```sh
efibootmgr -v
```

Se vedete vecchie voci (ad esempio io ci avevo trovato ancora Debian perché chi avevo usato il PC prima di me aveva installato quello, ma ora usavo Pop) potete valutare se eliminarle.

### 6. Pacchetti da installare

Purtroppo non sono sicuri che questa lista di pacchetti sia corretta.
L'ho ricostrutita vedendo quali pacchetti ho installato.

```sh
sudo apt install tpm2-initramfs-tool tpm2-tools efitools 
```

È possibile che sia necessario installare anche altri pacchetti come anche che qualcuno sia superfluo.


## Certificati Secure Boot

SecureBoot verifica che i componenti usati in fasi di avvio del PC siano firmati.

I cerficati validi per la firma sono di due tipi: `db`, una lista di cerficati firmata a sua volta a catena dal produttore del PC, `MOK` (machine owner key) dei certificati di cui un sistema operativo in esecuzione può richiedere l'aggiunta e poi devono essere confermati al successivo riavvio (richiede un software particolare per funzionare).

Per firmare la UKI ci serve una coppia chiave privata-certificato e che il certificato sia aggiunto alla lista `db` o alla lista `MOK`.

NOTA: Per ragione di sicurezza è ovviamente opportuno che le chiavi private siano visibili solo da root. Quindi impostare owner `root`, permesso `600`.

Oltre ai certificati `db`/`MOK` esistono altri liste di certificati, se va bene non dobbiamo avere a che fare con loro, se va male (a me è successo con il Dell) ci toccherà:
* `PK` un singolo cerficato fornito di default dal costruttore del PC, che è usato per controllare tutti gli altri;
* `KEK` una lista di cerficati firmati con il `PK` e che vengono usato, a loro volta, per firmare tutti i certificati `db` validi;
* `dbx` lista firme revocate.

### Trovare o generare il certificato

**1. Controllare se Ubuntu c'ha già pensato** 

Se vi va bene Ubuntu, in fase di installazione, genera un certificato e richiede che sia aggiunto alla lista `MOK`.

Normalmente questi si trovato in `/var/lib/shim-signed/mok/`. Ovviamente per ragioni di sicurezza la chiave privata a visibile solo da utente root.

Se questi certificati esistono allora bisogna controllare se siano registrati sul BIOS.

Eseguire

```sh
sudo mokutil --list-enrolled
```

e se c'è qualcosa confrontate con il certificato trovato sul disco

```sh
openssl x509 -in /var/lib/shim-signed/mok/NOMETROVATO.der -noout -text
```

Se uno dei certificati trovati corrisponde allora sei a posto e puoi ignorare i punti successivi.

**2. Generare un coppia di cerfiticati**

Generiamo il certificato in una cartella si sistema: possiamo ad esempio creare una cartella in `/opt` oppure anche usare l'home di `/root`.

```sh
sudo su
cd /root
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=nomecognome@email.com/" -keyout NOME.key -out NOME.crt -days 1800 -nodes -sha256
openssl x509 -in NOME.crt -out NOME.der -outform DER
```

### Aggiungere il certificato

Se c'ha già pensato Ubuntu non è necessario, passare oltre.

**1. Proviamo ad aggiungerlo come MOK**

Eseguire questo commando e seguire le istruzioni. Se chiede una password sarà necessario reinserirla al riavvio per confermare il certificato.

```sh
mokutil --import PATH_TO_CERT.der
```

Al riavvio controllare con il commando sotto che il certificato sia registrato

```sh
sudo mokutil --list-enrolled
```

Se qualcosa non funziona passare allo step successivo.

**2. Proviamo ad aggiungere una certificato alla lista `db`**

Copiamo il cerficato nella ESP

```sh
mkdir /boot/efi/certs
cp PATH_TO_CERT.der /boot/efi/certs/NOME.cer
```

In internet consigliano di usare l'estensiano `cer` perché alcuni bios visualizzano file con questa estensione.

Riavviare e nelle impostazioni del BIOS cercare se è possibile trovare ed aggiungere il certificato da ESP come db.

Se fosse necessario inserire un UUID è possibile generarlo con

```sh
uuidgen --random
```

o con

```sh
python3 -c 'import uuid; print(uuid.uuid1())'
```

Per verificare è possibile visualizzare tutta la lista dei certificati in `db` da terminale con questo commando

```sh
sudo mokutil --db
```

**3. Generare e sostituire completamente tutti i cerficati**

L'ultima spiaggia è rimpiazzare i certificati originali del portatile.

Sul Dell ho dovuto fare così anche se ho verificato che comunque è possibile resettare la situazione.

Per fare questo è necessario:
* generare un certificato `PK` e uno `KEK`
* recuperare eventuali certificati `db` preesistenti che vogliamo mantenere
* convertire i vari certificati in 3 liste firmate di certificati in uno formato per BIOS UEFI
* Nel BIOS impostare SecureBoot in "setup mode" o "audit mode"
* Avviare un certo eseguibile chiamato `KeyTool.efi` fornito dal pacchetto `efitools`

TODO: trovare la guida online migliore che spiega come fare.

## Unified Kernel Image

### Step0: backup e dimensione dell'initrd

Visto che nell'ESP c'è in genere poco spazio, riduciamo le dimensioni dell'initrd cambiamo il parametro che regola quali moduli vengono copiati all'interno di esso.

```
sudo nano /etc/initramfs-tools/initramfs.conf
```

e mettiamo `MODULES=dep`.

Con questo parametro la initrd conterrà meno moduli: ad esempio non conterrà il microcode per CPU AMD se il computer attuale ha una CPU Intel.

Poi vogliamo anche che il vecchio initrd venga salvato come backup e non sovrascritto.

```
sudo nano /etc/initramfs-tools/update-initramfs.conf
```

e mettiamo `backup_initramfs=yes`.

Ora, per essere sicuri che `MODULES=dep` copi nell'initrd tutto quello che serve buildiamo e riavviamo. In caso di problemi avviamo il sistema dal backup e annulliamo le modifiche mettendo `most` nel primo file.

```
update-initramfs -u
reboot
```

### Step1: Pezzi

```sh
stud_path=`ls -1 /var/lib/flatpak/runtime/org.gnome.Platform/x86_64/*/*/files/lib/systemd/boot/efi/linuxx64.efi.stub|sort -r|head -n 1`
```

### Step2: Script

Salvare questo come

```sh
#!/bin/bash

esp_path="/boot/efi"
initrd_path="/boot/initrd.img"
linux_path="/boot/vmlinuz"
sbkeys_path="PATH_TO_DB_OR_MOK_KEY"
cmdline_path="PATH_TO_CMDLINE_FILE"
splash_file_path="/opt/mkuki/uki_splash_ubuntu_framework.bmp"
uki_path="$esp_path/EFI/NOMESISTEMA/LinuxUKI.efi"
stud_path="PATH_TO_STUD_FILE"

align="$(objdump -p $stud_path | awk '{ if ($1 == "SectionAlignment"){print $2} }')"
align=$((16#$align))
osrel_offs="$(objdump -h "$stud_path" | awk 'NF==7 {size=strtonum("0x"$3); offset=strtonum("0x"$4)} END {print size + offset}')"
osrel_offs=$((osrel_offs + "$align" - osrel_offs % "$align"))
cmdline_offs=$((osrel_offs + $(stat -Lc%s "/usr/lib/os-release")))
cmdline_offs=$((cmdline_offs + "$align" - cmdline_offs % "$align"))
splash_offs=$((cmdline_offs + $(stat -Lc%s "$cmdline_path")))
splash_offs=$((splash_offs + "$align" - splash_offs % "$align"))
initrd_offs=$((splash_offs + $(stat -Lc%s "$splash_file_path")))
initrd_offs=$((initrd_offs + "$align" - initrd_offs % "$align"))
linux_offs=$((initrd_offs + $(stat -Lc%s "$initrd_path")))
linux_offs=$((linux_offs + "$align" - linux_offs % "$align"))

echo -- Generating UKI image $efi_path ...

temp_file_name=$(mktemp)

objcopy \
    --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=$(printf 0x%x $osrel_offs) \
    --add-section .cmdline="$cmdline_path" \
    --change-section-vma .cmdline=$(printf 0x%x $cmdline_offs) \
    --add-section .splash="$splash_file_path" \
    --change-section-vma .splash=$(printf 0x%x $splash_offs) \
    --add-section .initrd="$initrd_path" \
    --change-section-vma .initrd=$(printf 0x%x $initrd_offs) \
    --add-section .linux="$linux_path" \
    --change-section-vma .linux=$(printf 0x%x $linux_offs) \
    "$stud_path" "$temp_file_name"

if [ -f "$uki_path" ]; then
  echo -- Saving old image to "$uki_path.old" ...
  mv "$uki_path" "$uki_path.old"
fi

echo -- Signing UKI image

sbsign \
  --key "$sbkeys_path.key" \
  --cert "$sbkeys_path.crt" \
  --output "$uki_path" \
  "$temp_file_name"
```

