import paho.mqtt.client as mqtt
import socket
import struct
import json
import subprocess
import time
import threading
import crcmod

# Configuración del CRC-16 (usando CRC-16-CCITT)
crc16 = crcmod.predefined.mkCrcFun('crc-ccitt-false')

def generar_comando(pitch, yaw):
    # Cabeceras y bytes fijos
    cabecera = [0x55, 0x66, 0x01, 0x04, 0x00, 0x00, 0x00, 0x0e]
    
    # Convertir pitch y yaw a bytes (little-endian)
    pitch_bytes = struct.pack('<h', int(pitch * 10))  # Escalar pitch por 10
    yaw_bytes = struct.pack('<h', int(yaw * 10))      # Escalar yaw por 10
    
    # Construir el mensaje sin CRC
    mensaje_sin_crc = cabecera + list(yaw_bytes) + list(pitch_bytes)
    
    # Calcular el CRC-16
    crc = crc16(bytearray(mensaje_sin_crc))
    crc_bytes = struct.pack('<H', crc)  # CRC en little-endian
    
    # Construir el mensaje completo
    mensaje_completo = mensaje_sin_crc + list(crc_bytes)
    
    # Empaquetar los bytes en el formato correcto
    data = struct.pack('B' * len(mensaje_completo), *mensaje_completo)
    
    return data

# Levantar configuraciones del JSON
with open("config.json", 'r') as f:
    config = json.load(f)
    id_drone = config["id_drone"]
    ffmpeg_input_url = config["ffmpeg_input_url"]
    ffmpeg_output_url = config["ffmpeg_output_url"]
    mqtt_broker = config["mqtt_broker"]
    mqtt_port = config["mqtt_port"]
    server_address = config["server_address"]
    server_port = config["server_port"]

# Función para ejecutar el comando ffmpeg en un hilo secundario
def start_ffmpeg_stream():
    ffmpeg_command = [
        "ffmpeg", "-re", "-i", ffmpeg_input_url,
        "-c:v", "libx264", "-preset", "veryfast", "-tune", "zerolatency",
        "-f", "mpegts", f"{ffmpeg_output_url}?streamid=srt://video-testing.dronesecurity.com.ar:9999/app/{id_drone}&latency=2000000"
    ]
    subprocess.run(ffmpeg_command)

# Crear y empezar el hilo para la transmisión
ffmpeg_thread = threading.Thread(target=start_ffmpeg_stream)
ffmpeg_thread.start()

# Crear un socket UDP
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Variable de estado para la grabación
is_recording = False

# Callback que se ejecuta cuando se conecta al broker
def on_connect(client, userdata, flags, rc):
    print("Conectado con código de resultado: " + str(rc))
    # Se suscribe al tópico
    client.subscribe("/gimbal/control")

# Callback que se ejecuta cuando se recibe un mensaje
def on_message(client, userdata, msg):
    global is_recording
    try:
        payload_json = json.loads(msg.payload.decode())
        drone_validation = payload_json.get("id_drone")

        if drone_validation != id_drone:
            print("El mensaje recibido no es para este drone.")
            return

        if "pitch" in payload_json and "yaw" in payload_json:
            pitch = int(payload_json.get("pitch"))
            yaw = int(payload_json.get("yaw"))

            print("Valor de pitch recibido: ", pitch)
            print("Valor de yaw recibido: ", yaw)

            if -90 <= pitch <= 20 and -120 <= yaw <= 120:
                data = generar_comando(pitch, yaw)
            else:
                print("Combinación de pitch y yaw no válida.")
                return
            
        elif "recordState" in payload_json:
            record = payload_json.get("recordState")

            print("Valor de record recibido: ", record)

            if record == "start" and not is_recording:
                print("Iniciar grabación.")
                data = struct.pack('BBBBBBBBBBB', 0x55,0x66,0x01,0x01,0x00,0x00,0x00,0x0c,0x02,0x76,0xee)
                is_recording = True
            elif record == "stop" and is_recording:
                print("Detener grabación.")
                data = struct.pack('BBBBBBBBBBB', 0x55,0x66,0x01,0x01,0x00,0x00,0x00,0x0c,0x02,0x76,0xee)
                is_recording = False
                mission = payload_json.get("id_mission")
                # Ejecutar el script sf.sh y pasarle el id_mission
                time.sleep(15)
                subprocess.Popen(["/bin/bash", "sf.sh", mission])
            else:
                print("Valor de record no válido.")
                return
        
        sock.sendto(data, (server_address, server_port))

    except ValueError:
        print("El mensaje recibido no es un número válido.")

# Crear un cliente MQTT
client = mqtt.Client()

# Asignar los callbacks
client.on_connect = on_connect
client.on_message = on_message

# Conectar al broker
client.connect(mqtt_broker, mqtt_port, 60)

# Mantener la conexión MQTT abierta y esperar mensajes
client.loop_forever()

# Cerrar el socket
sock.close()