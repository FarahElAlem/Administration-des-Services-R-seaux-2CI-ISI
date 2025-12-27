const users = $input.all();
let message = `🚨 ALERTE SÉCURITÉ - Nouveaux utilisateurs détectés\n\n`;
message += `Nombre de nouveaux comptes : ${users.length}\n\n`;

users.forEach((user, index) => {
  message += `${index + 1}. ${user.json.username}\n`;
  message += `   📧 Email: ${user.json.email}\n`;
  message += `   🕐 Créé le: ${user.json.created_at}\n\n`;
});

return [{ json: { alert_message: message } }];
