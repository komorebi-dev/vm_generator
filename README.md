# VM GENERATOR

## vm.sh

> [!NOTE]
> Ce script est basé sur un script similaire fait par [@shaolin-peanut](https://github.com/shaolin-peanut) pour sa Piscine OCAML, lui même basé sur celui de [@t-h2o](https://github.com/t-h2o) pour son Inception

Le script [vm.sh](./vm.sh) permet de créer, via la CLI de VirtualBox, une VM depuis une image (`.iso`, `.vdi`).

Le script est fait pour télécharger une archive contenant l'image en indiquant une URL dans la variable `URL_DOWNLOAD`.

>[!CAUTION]
> Les paths de téléchargements sont spécifiquement faits pour les Linux (Ubuntu) de 42 Lausanne, modifier ces paths pour qu’ils conviennent a votre environnement.

>[!WARNING]
> Si vous changé `URL_DOWNLOAD` (donc d'OS et d'image), il faut modifier en conséquence toutes les autres variables (`DISTRO_NAME`, `COMPUTER_ARCHITECTURE`, `ARCHIVE_NAME`, `EXTRACTED_DIR`, `VDI_NAME`, `OS_TYPE` et `VM_NAME`) liées a l'extraction de l'archive, l'emplacement de l'image tirée de l'archive, le nom de l'OS ... pour que ces variables correspondent a la hiérarchie de l'archive et le nom de l'OS.

Pour le moment le script utilise/download une image Ubuntu-25.04 depuis l'url suivante: https://sourceforge.net/projects/osboxes/files/v/vb/55-U-u/25.04/

Le nom de l'archive est 64bit.7z et pour l'url complète, celle utilisée dans le script il faut ajouter `64bit.7z/download`.

L'utilisateur par défaut des images **osboxes** est `osboxes` avec comme mot de passe `osboxes.org`, c'est le même pour `root`.

Le script propose les fonctionnalités suivantes:
- télécharger l’archive avec l’image qui est dans la variable `URL_DOWNLOAD`, extract l’archive en ouvrant le dossier de téléchargement et demandant a l'utilisateur de l’extraire (possibilité d’évolution en utilisant `tar -xvf` ou autre)
- créer la VM, modifie/précise la config (RAM, VRAM …)
- ajoute un shared folder entre la VM et l’hôte, demande le path du dossier hôte qui sera partagé sur la VM, ce dossier sera monté a `/media/sf_shared/`
- start la VM
- delete la VM y compris des dossiers associés (`EXTRACTED_DIR`, `/home/${whoami}/VirtualBox VMs/${VM_NAME}` voir la doc de la commande `VBoxManage unregistervm` avec l’option `--delete`)
- delete le dossier d’extraction de l’archive (`${DL_DIR}/${DISTRO_NAME}/`)

### Explications des variables globales

>[!CAUTION]
> J'ai obtenu et construit ces variables en suivant la structure de l’URL et l'archive en elle-même qui est téléchargée depuis [sourceforge.net](https://sourceforge.net), spécifiquement celles de [osboxes](https://sourceforge.net/projects/osboxes) dont l'architecture de l'archive peut potentiellement changer d'une archive a une autre et d'autant plus en utilisant une autre source pour les téléchargements.


`DL_DIR` ==> dossier utilisé comme base pour télécharger l'archive, puis l'extraire

`URL_DOWNLOAD` ==> l'url d'où télécharger l'archive

`DISTRO_NAME` ==> nom de la distribution/OS téléchargé, utilisé pour des variables suivantes pour des dossiers\

`COMPUTER_ARCHITECTURE` ==> l'architecture de l'image (32bit, 64bit ...), utilisé pour le dossier de l'archive après extraction

`ARCHIVE_NAME` ==> dossier de destination du téléchargement de l'image, construit avec `DL_DIR` + `DISTRO_NAME` et le type d'archive (7z, zip ...)

`EXTRACTED_DIR` ==> path vers le dossier après avoir extrait l'archive, construit avec `DL_DIR` + `DISTRO_NAME` + `COMPUTER_ARCHITECTURE`, cette structure est nécessaire vis-a-vis du nom donné a l'archive et le contenu de celle-ci une fois extraite qui comprend un dossier correspondant au `COMPUTER_ARCHITECTURE`

`VDI_NAME` ==> path complet vers l'image (`.vdi`, `.iso` ...) dans le dossier extrait

`OS_TYPE` ==> le type d'OS de la VM !! utiliser `VBoxManage list ostypes` pour avoir la liste de tous les OS disponibles et utiliser le champ `ID` de l'OS avec la bonne version qui a été téléchargé

`VM_NAME` ==> le nom de la VM


## commands.sh

J’ai également créer le script [commands.sh](./commands.sh) qui est a exécuter une fois que la VM est lancée et être passé en root, ce script permet de rassembler toutes les commandes a exécuter pour finir la configuration de la VM (ajout de l'utilisateur par défaut au groupe permettant l’accès aux shared folder, installer des utilitaires ...).

Par exemple dans la version actuelle, ce script contient des commandes permettant de:
- Ajouter l'utilisateur `osboxes` au groupe `vboxsf` (groupe VirtualBox pour les dossiers partages) afin que l'utilisateur par défaut et les browsers puissent accéder aux shared folders (qui sont montes a `/media/sf_shared`),
- Installer quelques utilitaires, ici `virtualenv` et `curl` sans demander de prompt de confirmation (`-y`) et en background (`&`) en attendant que tous les téléchargements se terminent (`wait`),
- Installer `docker` en utilisant le script fourni par la doc, spécifiquement pour Ubuntu: [script installation docker ubuntu](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)
  pour cette étape, le script est télécharger de [https://get.docker.com](https://get.docker.com) puis exécuté en background pour attendre son téléchargement et enfin l'utilisateur `osboxes` est ajouté au groupe `docker`

<details>
  <summary>doc</summary>

  [Chapter 8. VBoxManage | virtualbox man](https://www.virtualbox.org/manual/ch08.html)

  [VirtualBox Images | osboxes](https://www.osboxes.org/virtualbox-images/)

  [Password for virtual machines | osboxes](https://www.osboxes.org/faq/what-are-the-credentials-for-virtual-machine-image/)

  [OSBoxes | sourceforge](https://sourceforge.net/projects/osboxes/)

  [Oracle VM VirtualBox User Manual | oracle](https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage.html)

  [Managing Oracle VM VirtualBox from the Command Line | oracle](https://www.oracle.com/technical-resources/articles/it-infrastructure/admin-manage-vbox-cli.html)
</details>