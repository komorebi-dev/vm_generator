# VM GENERATOR

## vm.sh

> [!NOTE]
> Ce script est basé sur un script similaire fait par [@shaolin-peanut](https://github.com/shaolin-peanut) pour sa Piscine OCAML, lui même basé sur celui de [@t-h2o](https://github.com/t-h2o) pour son Inception

Le script [vm.sh](./vm.sh) permet de créer, via la CLI de VirtualBox, une VM depuis une image (`.iso`, `.vdi`).

Le script est fait pour télécharger une archive contenant l'image en indiquant une URL dans la variable `URL_DOWNLOAD`.

>[!WARNING]
> Les paths de téléchargements sont spécifiquement faits pour les Linux (Ubuntu) de 42 Lausanne, modifier ces paths pour qu’ils conviennent a votre environnement.

> [!WARNING]
> Beaucoup de problèmes de collusion peuvent apparaître si vous créez des VM utilisant le même `iso`
> Je conseille donc de n’avoir qu’une VM par `iso` lorsque l’on run le script même si celui-ci supporte normalement d’avoir plusieurs VM

L'utilisateur par défaut des images **osboxes** est `osboxes` avec comme mot de passe `osboxes.org`, c'est le même pour `root`.

Ubuntu Server : https://sourceforge.net/projects/osboxes/files/v/vb/59-U-u-svr/25.04/64bit.7z/download
>[!NOTE]
> Il faut installer les `guest additions` de VirtualBox lorsqu'on utilise Ubuntu Server
> `sudo apt update`
> `sudo apt install virtualbox-guest-utils virtualbox-guest-x11 -y`
> `sudo reboot`
> reprendre le processus habituel avec `commands.sh` mount a `/media/...`

Ubuntu : https://sourceforge.net/projects/osboxes/files/v/vb/55-U-u/25.04/64bit.7z/download

Le script propose les fonctionnalités suivantes:
- télécharger l’archive avec l’image qui est dans la variable `URL_DOWNLOAD`, extract l’archive en ouvrant le dossier de téléchargement et demandant a l'utilisateur de l’extraire (possibilité d’évolution en utilisant `tar -xvf` ou autre => pas dispo sur les ordis de 42)
- créer la VM, modifie/précise la config (RAM, VRAM …), port forwarding 22 -> 2222 (ssh)
- ajoute un/des shared folder entre la VM et l’hôte, demande le path du dossier hôte qui sera partagé sur la VM, ce dossier sera monté a `/media/sf_{nom du dossier}`
- start la VM, propose en `headless` ou non
- delete la VM y compris des dossiers associés (`/home/${whoami}/VirtualBox VMs/${VM_NAME}`)
- delete le dossier d’extraction de l’archive

### Explications des variables globales

>[!CAUTION]
> Les variables globales (URL_DOWNLOAD, COMPUTER_ARCHITECTURE, ARCHIVE_PATH, OS_TYPE and VM_NAME) sont importantes pour la bonne execution du script
> Modifier les avec attention

`DL_DIR`                ==> dossier utilisé comme base pour télécharger l'archive, puis l'extraire

`URL_DOWNLOAD`          ==> l'url d'où télécharger l'archive

`COMPUTER_ARCHITECTURE` ==> l'architecture de l'image (32bit, 64bit ...)

`ARCHIVE_NAME`          ==> le nom du fichier pour le téléchargement de l'archive (contenant l'`.iso`/`.vdi`)

`ARCHIVE_PATH`          ==> la destination complète de l'archive (`DL_DIR` + `ARCHIVE_NAME`)

`OS_TYPE`               ==> le type d'OS de la VM !! utiliser `VBoxManage list ostypes` pour avoir la liste de tous les OS disponibles et utiliser le champ `ID` de l'OS avec la bonne version qui a été téléchargé

`VM_NAME`               ==> le nom de la VM


## commands.sh

J’ai également créer le script [commands.sh](./commands.sh) qui est a exécuter une fois que la VM est lancée et être passé en root, ce script permet de rassembler toutes les commandes a exécuter pour finir la configuration de la VM (ajout de l'utilisateur par défaut au groupe permettant l’accès aux shared folder, installer des utilitaires ...).

Une modification nécessaire a faire est l'ajout de l'utilisation `osboxes` au groupe `vboxsf` (groupe VirtualBox pour les dossiers partages) pour que l'utilisateur par défaut et les browsers puissent accéder aux shared folders (qui sont montes a `/media/sf_...`)


Exemples d'utilities installer et setup:

<details>
  <summary>`openssh-server`</summary>

Le port forwarding est deja effectue sur le port 2222 du host
```bash
sudo apt-get -y install openssh-server &
PID=$!
wait $PID

sudo systemctl enable --now ssh &
PID=$!
wait $PID

sudo reboot
```
</details>

<details>
  <summary>`opam`</summary>

```bash
sudo apt-get -y install opam &
PID=$!
wait $PID

echo "1" | opam init &
PID=$!
wait $PID

eval $(opam env --switch=default)

sudo reboot
```
</details>

<details>
  <summary>`docker`</summary>

```bash
curl -fsSL https://get.docker.com -o get-docker.sh &
PID=$!
wait $PID
sudo sh ./get-docker.sh &
PID=$!
wait $PID
sudo usermod -aG docker osboxes && newgrp docker

sudo reboot
```
</details>


<details>
  <summary>doc</summary>

  [Chapter 8. VBoxManage | virtualbox man](https://www.virtualbox.org/manual/ch08.html)

  [VirtualBox Images | osboxes](https://www.osboxes.org/virtualbox-images/)

  [Password for virtual machines | osboxes](https://www.osboxes.org/faq/what-are-the-credentials-for-virtual-machine-image/)

  [OSBoxes | sourceforge](https://sourceforge.net/projects/osboxes/)

  [Oracle VM VirtualBox User Manual | oracle](https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage.html)

  [Managing Oracle VM VirtualBox from the Command Line | oracle](https://www.oracle.com/technical-resources/articles/it-infrastructure/admin-manage-vbox-cli.html)
</details>