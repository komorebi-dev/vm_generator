#!/bin/bash
# based on a script made by https://github.com/shaolin-peanut for his OCAML Piscine
# and one by https://github.com/t-h2o for his Inception

RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"
YELLOW="\033[0;33m"
DL_DIR="/goinfre/$(whoami)" # folder to use to download/extract ! goinfre is only on the mac at school !
RAM_SIZE="8192"

# Variables to fill, includes the URL to download the iso from, some folder name ...
URL_DOWNLOAD="https://sourceforge.net/projects/osboxes/files/v/vb/55-U-u/25.04/64bit.7z/download"
DISTRO_NAME="ubuntu" # name of the distro, used for later destinations folder
COMPUTER_ARCHITECTURE="64bit" # most likely 64bit, corresponds to the name of the archive
ARCHIVE_NAME="${DL_DIR}/${DISTRO_NAME}.7z" # destination folder of the download
EXTRACTED_DIR="${DL_DIR}/${DISTRO_NAME}/${COMPUTER_ARCHITECTURE}" # destination folder of the extracted archive
VDI_NAME="${EXTRACTED_DIR}/Ubuntu 25.04 (64bit).vdi" # path + file name of the VDI in the extracted folder
OS_TYPE="Ubuntu_64" # use 'VBoxManage list ostypes' to list the available OS types, use the ID field of the wanted OS
VM_NAME="Ubuntu"


download_vdi() {
    echo "Downloading the VDI from ${URL_DOWNLOAD} ..."
    if [ ! -f "${VDI_NAME}" ]; then
        echo "VDI file not found. Checking archive..."

        if [ ! -f "${ARCHIVE_NAME}" ]; then
            echo -e "${GREEN}Starting download of the VDI from ${URL_DOWNLOAD} ...${RESET}"
            curl -L -o "${ARCHIVE_NAME}" "${URL_DOWNLOAD}"
        else
            echo -e "${YELLOW}Archive already downloaded: ${ARCHIVE_NAME}${RESET}\n"
        fi

        while [ ! -f "${VDI_NAME}" ]; do
            echo "VDI file not found."
            echo "Make sure ${VDI_NAME} match with the content extracted in ${EXTRACTED_DIR}"
            echo -e "${YELLOW}Open ${DL_DIR}?${RESET}"
            read -p "Choice (y): " yn
            if [ "$yn" == "y" ]; then
                open "${DL_DIR}"
            else
                echo "Make sure you extract the archive at ${DL_DIR} and the VDI file name matches with the variable VDI_NAME"
            fi
            read -p "Press Enter after extracting the archive file..."
        done
        echo -e "${GREEN}The virtual disk image is ready at ${VDI_NAME}${RESET}\n"
    else
        echo -e "${GREEN}VDI file already exists: ${VDI_NAME}${RESET}\n"
    fi
}

create_vm() {
    if VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
        echo -e "${RED}VM '${VM_NAME}' already exists. Returning to menu.${RESET}"
        main
    fi

    echo -e "${YELLOW}Creating VirtualBox VM '${VM_NAME}'...${RESET}"
    VBoxManage createvm --name "${VM_NAME}" --ostype "${OS_TYPE}" --register
    VBoxManage modifyvm "${VM_NAME}" --memory "${RAM_SIZE}" --cpus 2 --nic1 nat
    VBoxManage storagectl "${VM_NAME}" --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach "${VM_NAME}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${VDI_NAME}"
    VBoxManage modifyvm "${VM_NAME}" --audio-driver none
    VBoxManage modifyvm "${VM_NAME}" --vram 32
    VBoxManage modifyvm "${VM_NAME}" --clipboard-mode=bidirectional
    echo -e "${GREEN}VirtualBox VM '${VM_NAME}' successfully created${RESET}"
}

add_shared_folder() {
    echo -e "${GREEN}Adding shared folder...${RESET}"
    read -p "Enter path to valid shared folder: " SHARED_FOLDER
    while [ ! -d "${SHARED_FOLDER}" ]; do
        echo -e "${RED}Folder does not exist. Please provide a valid shared folder path.${RESET}"
        read -p "Enter path to valid shared folder: " SHARED_FOLDER
    done

    VBoxManage sharedfolder add "${VM_NAME}" --name "shared" --hostpath "${SHARED_FOLDER}" --automount
    VBoxManage setextradata "${VM_NAME}" "VBoxInternal2/SharedFoldersEnableSymlinksCreate/${SHARED_FOLDER}" 1
    echo -e "${GREEN}Shared folder added.${RESET}"
}

delete_vm() {
    existing_vm=$(VBoxManage list vms)
    if [ -z "${existing_vm}" ]; then
        echo -e "${RED}No existing VMs to delete${RESET}\n"
        main
    fi

    echo "List of existing VMs:"
    echo "$existing_vm"
    read -p "Which VM to delete: " VM_TO_DELETE
    if ! echo "$existing_vm" | grep -q "${VM_TO_DELETE}"; then
        echo -e "${RED}${VM_TO_DELETE} does not exist. Please provide a valid VM name.${RESET}"
        delete_vm
    fi

    echo "Unregistering and deleting VM '${VM_TO_DELETE}'..."
    # https://www.virtualbox.org/manual/ch08.html#vboxmanage-unregistervm
    # Unregister a VM
    # --delete -> automatically deletes some files related to the VM present in /home/${whoami}/VirtualBox VMs/${VM_NAME}
    VBoxManage unregistervm "${VM_TO_DELETE}" --delete
    echo -e "${GREEN}VM '${VM_TO_DELETE}' deleted.${RESET}"
}

delete_extracted_archive_folder() {
    echo -e "${YELLOW}This will delete the extracted archive folder '${DL_DIR}/${DISTRO_NAME}/'${RESET}"
    read -p "Confirm (y): " confirmation
    if [ "${confirmation}" == "y" ]; then
        rm -rf "${DL_DIR}/${DISTRO_NAME}/"
        echo -e "${GREEN}VDI file and extracted folder deleted.${RESET}\n"
    else
        echo -e "${YELLOW}${VDI_NAME} file not deleted.${RESET}\n"
    fi
}

menu() {
    echo "VirtualBox VM Manager Script:"
    echo "[1] Download VDI"
    echo "[2] Create VM"
    echo "[3] Add shared folder"
    echo "[4] Start VM"
    echo "[5] Delete VM"
    echo "[6] Delete extracted archive folder"
    echo "[7] Exit"
    read -p "Choose an option [1-7]: " choice

    if [[ $choice -ge 1 && $choice -le 7 ]]; then
        return $choice
    else
        echo -e "\n${RED}Invalid choice. Try again${RESET}\n"
        menu
    fi
}

main() {
    if [ -z "${URL_DOWNLOAD}" ] || [ -z "${ARCHIVE_NAME}" ] || [ -z "${EXTRACTED_DIR}" ] || \
    [ -z "${VDI_NAME}" ] || [ -z "${OS_TYPE}" ] || [ -z "${VM_NAME}" ]; then
        echo -e "${RED}One or more required variables are empty.${RESET}"
        echo "The variables to check are URL_DOWNLOAD, ARCHIVE_NAME, EXTRACTED_DIR, VDI_NAME, OS_TYPE and VM_NAME."
        exit 1
    else
        echo "--------------------"
        echo -e "${GREEN}All variables are set correctly.${RESET}"
        echo "--------------------"
    fi

    menu

    answer=$?
    if [ "${answer}" -eq 1 ]; then
        download_vdi
    elif [ "${answer}" -eq 2 ]; then
        create_vm
    elif [ "${answer}" -eq 3 ]; then
        add_shared_folder
    elif [ "${answer}" -eq 4 ]; then
        # https://www.virtualbox.org/manual/ch08.html#vboxmanage-startvm
        # Start the VM with name ${VM_NAME}
        VBoxManage startvm "${VM_NAME}"
        echo -e "${GREEN}VM ${VM_NAME} started${RESET}"
        echo "If a shared folder has been added it will be mounted at /media/sf_shared"
    elif [ "${answer}" -eq 5 ]; then
        delete_vm
    elif [ "${answer}" -eq 6 ]; then
        delete_extracted_archive_folder
    elif [ "${answer}" -eq 7 ]; then
        exit 1
    fi

    main
}

main
