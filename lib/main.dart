const iothub = require('azure-iothub');
const { Message } = require('azure-iot-common');

module.exports = async function (context, req) {
  const connectionString = process.env.IOTHUB_CONNECTION_STRING;
  context.log("🔍 Connexion Azure IoT :", connectionString);

  if (!connectionString || !connectionString.includes("HostName=")) {
    context.log("❌ Chaîne de connexion manquante ou invalide.");
    context.res = {
      status: 500,
      body: "Chaîne de connexion IOTHUB_CONNECTION_STRING invalide ou absente.",
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json"
      }
    };
    return;
  }

  // ✅ Lecture depuis le body JSON
  const body = req.body || {};
  const deviceId = body.deviceId;
  const color = body.color;

  context.log(`📦 Reçu depuis Flutter : deviceId = ${deviceId}, color = ${color}`);

  if (!deviceId || !color) {
    context.res = {
      status: 400,
      body: "deviceId ou color manquant",
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json"
      }
    };
    return;
  }

  const serviceClient = iothub.Client.fromConnectionString(connectionString);
  const message = new Message(JSON.stringify({ color }));

  try {
    await new Promise((resolve, reject) => {
      serviceClient.open(err => {
        if (err) return reject(err);
        serviceClient.send(deviceId, message, err => {
          if (err) reject(err);
          else resolve();
        });
      });
    });

    context.res = {
      status: 200,
      body: `✅ Couleur ${color} envoyée à ${deviceId}`,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json"
      }
    };
  } catch (err) {
    context.log("❌ Erreur lors de l’envoi :", err);
    context.res = {
      status: 500,
      body: "Erreur lors de l'envoi du message.",
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Content-Type": "application/json"
      }
    };
  }
};
