# A8mini-gimbal-camera-control

## Detalles e Instrucciones por MQTT

- **Conexión:** `your_server_ip`
- **Escribir en el tópico:** `/gimbal/control`
- **Instrucciones en formato JSON:**

### Ejemplo

Para iniciar la grabación:

````json
{"id_drone": "D001", "recordState": "start"}

Para pausar la grabación:
```json
{"id_drone": "D001", "recordState": "stop", "id_mission": "M001"}

Comandos Disponibles
Ejemplo de Mensaje JSON para Centrar la Cámara
{
  "id_drone": "D001",
  "pitch": "0",
  "yaw": "0"
}
Ejemplo de Mensaje JSON para Rotar la Cámara Hacia Abajo 90°
{
  "id_drone": "D001",
  "pitch": "-90",
  "yaw": "0"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 20° Hacia Arriba
{
  "id_drone": "D001",
  "pitch": "20",
  "yaw": "0"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 90° Hacia la Izquierda
{
  "id_drone": "D001",
  "pitch": "0",
  "yaw": "-90"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 90° Hacia la Derecha
{
  "id_drone": "D001",
  "pitch": "0",
  "yaw": "90"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 30° Hacia Abajo
{
  "id_drone": "D001",
  "pitch": "-30",
  "yaw": "0"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 45° Hacia Abajo
{
  "id_drone": "D001",
  "pitch": "-45",
  "yaw": "0"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 45° a la Izquierda
{
  "id_drone": "D001",
  "pitch": "0",
  "yaw": "-45"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 45° a la Derecha
{
  "id_drone": "D001",
  "pitch": "0",
  "yaw": "45"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 45° Hacia la Izquierda y 45° Hacia Abajo
{
  "id_drone": "D001",
  "pitch": "-45",
  "yaw": "-45"
}
Ejemplo de Mensaje JSON para Rotar la Cámara 45° Hacia la Derecha y 45° Hacia Abajo
{
  "id_drone": "D001",
  "pitch": "-45",
  "yaw": "45"
}
````
