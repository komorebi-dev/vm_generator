#!/bin/bash
# based on a script made by https://github.com/shaolin-peanut for his OCAML Piscine
# and one by https://github.com/t-h2o for his Inception

RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"
YELLOW="\033[0;33m"
DL_DIR="/goinfre/$(whoami)" # folder to use to download/extract ! goinfre is only on the mac at school !
RAM_SIZE="4096"


URL_DOWNLOAD="https://sourceforge.net/projects/osboxes/files/v/vb/59-U-u-svr/25.04/64bit.7z/download"
COMPUTER_ARCHITECTURE="64bit"
ARCHIVE_NAME="ubuntu.7z" # file destination of the download
ARCHIVE_PATH="${DL_DIR}/${ARCHIVE_NAME}" # full destination path of the downloaded archive
OS_TYPE="Ubuntu_64" # use 'VBoxManage list ostypes' to list the available OS types, use the ID field of the wanted OS
VM_NAME="ubuntu"


list_existing_vms() {
    existing_vm_list=$(VBoxManage list vms)
    if [ -z "${existing_vm_list}" ]; then
        echo -e "${RED}No existing VMs${RESET}\n"
        main
    else
        echo "List of existing VMs:"
        echo "${existing_vm_list}"
    fi
}


download_vdi() {
    read -p "Download URL [default: ${URL_DOWNLOAD}]: " input_url
    URL_DOWNLOAD=${input_url:-$URL_DOWNLOAD}

    read -p "Computer architecture [default: ${COMPUTER_ARCHITECTURE}]: " input_arch
    COMPUTER_ARCHITECTURE=${input_arch:-$COMPUTER_ARCHITECTURE}

    read -p "Download directory [default: ${DL_DIR}]: " input_dl_dir
    DL_DIR=${input_dl_dir:-$DL_DIR}

    read -p "Output file name of the downloaded archive [default: ${ARCHIVE_NAME}]: " input_archive_name
    ARCHIVE_NAME=${input_archive_name:-$ARCHIVE_NAME}

    ARCHIVE_PATH="${DL_DIR}/${ARCHIVE_NAME}"

    echo "Downloading archive from ${URL_DOWNLOAD} to ${ARCHIVE_PATH} ..."

    if [ ! -f "${ARCHIVE_PATH}" ]; then
        echo -e "${GREEN}Starting download of the archive from ${URL_DOWNLOAD} ...${RESET}"
        curl -L --create-dirs --output "${ARCHIVE_PATH}" "${URL_DOWNLOAD}"
    else
        echo -e "${YELLOW}Archive already downloaded: ${ARCHIVE_PATH}${RESET}\n"
    fi

    echo -e "${YELLOW}Please extract the archive ${ARCHIVE_PATH}${RESET}"
    if command -v open >/dev/null 2>&1; then
        open "${ARCHIVE_PATH}" >/dev/null 2>&1 || true
    else
        echo "Open and extract the archive manually: ${ARCHIVE_PATH}"
    fi

    while true; do
        read -p "Enter full path to the .vdi or .iso file extracted from the archive: " input_vdi
        user_vdi=${input_vdi}

        if [ -f "${user_vdi}" ]; then
            VDI_PATH="${user_vdi}"
            echo -e "${GREEN}VDI file set to: ${VDI_PATH}${RESET}\n"
            break
        else
            echo -e "${RED}File not found at ${user_vdi}. Please provide a valid path to the .vdi or .iso file extracted from the archive.${RESET}\n"
        fi
    done
}

create_vm() {
    read -p "Enter the name of the VM to create [default: ${VM_NAME}]: " input_name
    input_name=${input_name:-$VM_NAME}

    if VBoxManage list vms | grep -q "\"${input_name}\""; then
        echo -e "${RED}VM '${input_name}' already exists. Returning to menu.${RESET}"
        main
    fi

    read -p "Enter the OS type for the VM [default: ${OS_TYPE}]: " input_os_type
    OS_TYPE=${input_os_type:-$OS_TYPE}

    echo -e "${YELLOW}Creating VirtualBox VM '${input_name}'...${RESET}"

    VBoxManage createvm --name "${input_name}" --ostype "${OS_TYPE}" --register
    VBoxManage modifyvm "${input_name}" --memory "${RAM_SIZE}" --cpus 2 --nic1 nat
    VBoxManage modifyvm "${input_name}" --natpf1 "Rule 1,tcp,127.0.0.1,2222,,22"
    VBoxManage storagectl "${input_name}" --name "SATA Controller" --add sata --controller IntelAHCI
    VBoxManage storageattach "${input_name}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${VDI_PATH}"
    VBoxManage modifyvm "${input_name}" --audio-driver none
    VBoxManage modifyvm "${input_name}" --vram 32
    VBoxManage modifyvm "${input_name}" --clipboard-mode=bidirectional
    VBoxManage modifyvm "${input_name}" --graphicscontroller=vmsvga
    echo -e "${GREEN}VirtualBox VM '${input_name}' successfully created${RESET}"
}

add_shared_folder() {
    list_existing_vms

    read -p "Which VM to add a shared folder to [default: ${VM_NAME}]: " target_vm
    target_vm=${target_vm:-$VM_NAME}

    if ! echo "${existing_vm_list}" | grep -q "\"${target_vm}\""; then
        echo -e "${RED}${target_vm} is not an existing VM. Please provide a valid VM name.${RESET}"
        add_shared_folder
    fi

    echo -e "${GREEN}Adding shared folder to '${target_vm}'...${RESET}"

    PWD=$(pwd)
    while true; do
        read -p "Enter path to use as shared folder [default: ${PWD}]: " SHARED_FOLDER
        SHARED_FOLDER=${SHARED_FOLDER:-$PWD}

        while [ ! -d "${SHARED_FOLDER}" ]; do
            echo -e "${RED}Folder does not exist. Please provide a valid shared folder path.${RESET}"
            read -p "Enter path to use as shared folder (default: ${PWD}): " SHARED_FOLDER
            SHARED_FOLDER=${SHARED_FOLDER:-$PWD}
        done

        FOLDER_NAME=$(basename "${SHARED_FOLDER}")

        # Sanitize the name
        SAFE_NAME=$(echo "${FOLDER_NAME}" | sed 's/[^a-zA-Z0-9_-]/_/g')

        echo -e "${GREEN}Adding shared folder '${SAFE_NAME}' -> '${SHARED_FOLDER}' to VM '${target_vm}'.${RESET}"

        VBoxManage sharedfolder add "${target_vm}" --name "${SAFE_NAME}" --hostpath "${SHARED_FOLDER}" --automount
        VBoxManage setextradata "${target_vm}" "VBoxInternal2/SharedFoldersEnableSymlinksCreate/${SAFE_NAME}" 1
        echo -e "${GREEN}Shared folder added successfully.${RESET}"

        read -p "Add another shared folder to '${target_vm}'? (y/N): " more
        more=${more:-N}
        if [[ "${more}" != "y" && "${more}" != "Y" ]]; then
            break
        fi
    done
}

start_vm() {
    list_existing_vms

    read -p "Which VM to start [default: ${VM_NAME}]: " target_vm
    target_vm=${target_vm:-$VM_NAME}

    if ! echo "${existing_vm_list}" | grep -q "\"${target_vm}\""; then
        echo -e "${RED}${target_vm} is not an existing VM. Please provide a valid VM name.${RESET}"
        start_vm
    fi

    read -p "Start VM '${target_vm}' headless? (y/N): " headless_choice
    headless_choice=${headless_choice:-N}

    if [[ "${headless_choice}" == "y" || "${headless_choice}" == "Y" ]]; then
        echo -e "${YELLOW}Starting VM '${target_vm}' headless...${RESET}"
        VBoxManage startvm "${target_vm}" --type headless
    else
        echo -e "${YELLOW}Starting VM '${target_vm}' with GUI...${RESET}"
        VBoxManage startvm "${target_vm}"
    fi

    echo -e "${GREEN}VM ${target_vm} started${RESET}"
    echo "If a shared folder has been added it will be mounted at /media/sf_<shared_folder_name> in the VM"
    echo -e "If the ISO comes from osboxes: ${GREEN}user => osboxes | password => osboxes.org (same for root)${RESET}"
}

poweroff_vm() {
    running_vm=$(VBoxManage list runningvms)
    if [ -z "${running_vm}" ]; then
        echo -e "${RED}No running VMs to power off${RESET}\n"
        main
    fi

    echo "List of running VMs:"
    echo "${running_vm}"

    read -p "Which VM to power off [default: ${VM_NAME}]: " target_vm
    target_vm=${target_vm:-$VM_NAME}

    if ! echo "${running_vm}" | grep -q "${target_vm}"; then
        echo -e "${RED}${target_vm} is not a running VM. Please provide a valid running VM name.${RESET}"
        poweroff_vm
    fi

    echo "Powering off VM '${target_vm}'..."
    VBoxManage controlvm "${target_vm}" poweroff
    echo -e "${GREEN}VM '${target_vm}' powered off.${RESET}\n"
}

delete_vm() {
    list_existing_vms

    read -p "Which VM to delete [default: ${VM_NAME}]: " target_vm
    target_vm=${target_vm:-$VM_NAME}

    if ! echo "$existing_vm_list" | grep -q "${target_vm}"; then
        echo -e "${RED}${target_vm} does not exist. Please provide a valid VM name.${RESET}"
        delete_vm
    fi

    echo "Unregistering and deleting VM '${target_vm}'..."

    # https://www.virtualbox.org/manual/ch08.html#vboxmanage-unregistervm
    # --delete -> automatically deletes some files related to the VM present in /home/${whoami}/VirtualBox VMs/${target_vm} and the VDI file
    VBoxManage unregistervm "${target_vm}" #--delete
    rm -rf "/home/$(whoami)/VirtualBox VMs/${target_vm}"

    echo -e "${GREEN}VM '${target_vm}' deleted.${RESET}"

    echo "Use the 'Delete extracted archive folder' option to fully delete the '${ARCHIVE_PATH}' folder ..."
}

delete_extracted_archive_folder() {
    echo -e "${YELLOW}Delete the extracted archive folder '${ARCHIVE_PATH}'${RESET} ?"
    read -p "Confirm (y/N): " confirmation
    if [[ "${confirmation}" == "y" || "${confirmation}" == "Y" ]]; then
        rm -rf "${ARCHIVE_PATH}"
        echo -e "${GREEN}Extracted archive folder deleted.${RESET}\n"
    else
        echo -e "${YELLOW}Extracted archive folder not deleted.${RESET}\n"
    fi
}

menu() {
    echo "VirtualBox VM Manager Script:"
    echo "[1] Download VDI"
    echo "[2] Create VM"
    echo "[3] Add shared folder"
    echo "[4] Start VM"
    echo "[5] PowerOff VM"
    echo "[6] Delete VM"
    echo "[7] Delete extracted archive folder"
    echo "[8] Exit"
    read -p "Choose an option [1-8]: " choice

    if [[ $choice -ge 1 && $choice -le 8 ]]; then
        return $choice
    else
        echo -e "\n${RED}Invalid choice. Try again${RESET}\n"
        menu
    fi
}

main() {
    echo -e "${GREEN}The variables URL_DOWNLOAD, COMPUTER_ARCHITECTURE, ARCHIVE_PATH, OS_TYPE and VM_NAME"
    echo -e "can be empty, you will be prompted to fill them during some steps of the script.${RESET}"
    echo -e "${YELLOW}Current values:${RESET}"
    echo -e "${YELLOW}URL_DOWNLOAD: ${URL_DOWNLOAD}${RESET}"
    echo -e "${YELLOW}COMPUTER_ARCHITECTURE: ${COMPUTER_ARCHITECTURE}${RESET}"
    echo -e "${YELLOW}ARCHIVE_PATH: ${ARCHIVE_PATH}${RESET}"
    echo -e "${YELLOW}OS_TYPE: ${OS_TYPE}${RESET}"
    echo -e "${YELLOW}VM_NAME: ${VM_NAME}${RESET}\n"

    menu

    answer=$?
    if [ "${answer}" -eq 1 ]; then
        download_vdi
    elif [ "${answer}" -eq 2 ]; then
        create_vm
    elif [ "${answer}" -eq 3 ]; then
        add_shared_folder
    elif [ "${answer}" -eq 4 ]; then
        start_vm
    elif [ "${answer}" -eq 5 ]; then
        poweroff_vm
    elif [ "${answer}" -eq 6 ]; then
        delete_vm
    elif [ "${answer}" -eq 7 ]; then
        delete_extracted_archive_folder
    elif [ "${answer}" -eq 8 ]; then
        exit 1
    fi

    main
}

main
