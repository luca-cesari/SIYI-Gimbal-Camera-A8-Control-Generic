#!/bin/bash

# Verificar si se pasó el argumento id_mission
if [ -z "$1" ]; then
    echo "Error: No se proporcionó el id_mission."
    exit 1
fi

ID_MISSION=$1

# Configuración de URL base, tipo de medio y directorio
BASE_URL="http://192.168.144.25:82/cgi-bin/media.cgi"
MEDIA_TYPE=1
DIRECTORY="100SIYI_VID"

# Configuración de FTP
FTP_SERVER="ftp.dronesecurity.com.ar"
FTP_USER="u920639079.files"
FTP_PASS="*Jc!Q^zrW9fes58S"
FTP_UPLOAD_DIR="uploads"  # Asegúrate de que no tenga una barra inicial

# Ruta de destino para los archivos descargados
DOWNLOAD_DIR="/home/drone06/videoUploads"

# Crear la carpeta de destino si no existe
if [[ ! -d "$DOWNLOAD_DIR" ]]; then
    mkdir -p "$DOWNLOAD_DIR"
fi

# Obtener el conteo de archivos en el directorio
count_response=$(curl -s -G "$BASE_URL/api/v1/getmediacount" \
    --data-urlencode "media_type=$MEDIA_TYPE" \
    --data-urlencode "path=$DIRECTORY")

# Extraer el valor de count usando jq
file_count=$(echo "$count_response" | jq -r '.data.count')

# Verificar si el conteo es válido
if [[ "$file_count" -lt 0 ]]; then
    echo "Error: No se pudo obtener el número de archivos en el directorio $DIRECTORY."
    exit 1
fi

echo "Número de archivos en $DIRECTORY: $file_count"

# Si hay archivos, proceder a obtener la lista de archivos
if [[ "$file_count" -gt 0 ]]; then
    list_response=$(curl -s -G "$BASE_URL/api/v1/getmedialist" \
        --data-urlencode "media_type=$MEDIA_TYPE" \
        --data-urlencode "path=$DIRECTORY" \
        --data-urlencode "start=0" \
        --data-urlencode "count=$file_count")

    # Extraer los nombres y URLs de los archivos
    file_names=$(echo "$list_response" | jq -r '.data.list[].name')
    file_urls=$(echo "$list_response" | jq -r '.data.list[].url')

    # Verificar que se hayan obtenido nombres y URLs
    if [[ -z "$file_names" || -z "$file_urls" ]]; then
        echo "Error: No se pudo obtener la lista de archivos en el directorio $DIRECTORY."
        exit 1
    fi

    # Crear un array de los archivos y ordenarlos alfabéticamente
    file_array=()
    while IFS= read -r file_name && IFS= read -r file_url; do
        file_array+=("$file_name|$file_url")
    done < <(paste <(echo "$file_names") <(echo "$file_urls"))

    # Ordenar el array por nombre de archivo
    sorted_files=($(for file in "${file_array[@]}"; do echo "$file"; done | sort))

    # Obtener el último archivo (el más reciente, en función del orden alfabético)
    last_file_info="${sorted_files[-1]}"
    last_file_name=$(basename "$(echo "$last_file_info" | cut -d'|' -f1)")
    last_file_url=$(echo "$last_file_info" | cut -d'|' -f2)

    echo "Último archivo encontrado: $last_file_name"
    echo "URL de descarga: $last_file_url"

    # Descargar el archivo en la ruta específica
    output_path="$DOWNLOAD_DIR/$last_file_name"
    curl -o "$output_path" "$last_file_url"

    # Verificar si el archivo se descargó correctamente
    if [[ ! -f "$output_path" ]]; then
        echo "Error: No se pudo descargar el archivo $last_file_name."
        exit 1
    fi

    echo "Archivo descargado en $output_path."

    # Obtener la fecha y hora actual
    current_datetime=$(date +"%Y%m%d_%H%M%S")

    # Crear el nuevo nombre del archivo basado en la fecha y hora
    new_file_name="${current_datetime}.mp4"
    new_output_path="$DOWNLOAD_DIR/$new_file_name"
    mv "$output_path" "$new_output_path"

    # Crear el directorio de destino en el servidor FTP paso a paso
    ftp_dir="${FTP_UPLOAD_DIR}/${ID_MISSION}"
    echo "Creando directorio en el servidor FTP: $ftp_dir"
    IFS='/' read -ra DIR_PARTS <<< "$ftp_dir"
    current_path=""
    for part in "${DIR_PARTS[@]}"; do
        current_path="$current_path/$part"
        curl -u "$FTP_USER:$FTP_PASS" "ftp://$FTP_SERVER$current_path" -Q "MKD $current_path"
    done

    # Subir el archivo a través de FTP
    echo "Subiendo $new_file_name a $ftp_dir ..."
    curl -T "$new_output_path" --user "$FTP_USER:$FTP_PASS" "ftp://$FTP_SERVER/$ftp_dir/$new_file_name"

    # Verificar si la subida fue exitosa
    if [[ $? -ne 0 ]]; then
        echo "Error: No se pudo subir el archivo $new_file_name al servidor FTP."
        exit 1
    fi

    # Eliminar el archivo descargado localmente
    rm "$new_output_path"
    echo "Archivo $new_file_name subido y eliminado localmente."
else
    echo "El directorio $DIRECTORY está vacío."
fi