const MessageEnvelope = {
  version: 1,
  fields: ['conversationId', 'senderId', 'ciphertext', 'type', 'sentAt']
};

function safetyNumber(publicKeyA, publicKeyB) {
  const merged = [publicKeyA, publicKeyB].sort().join(':');
  let hash = 0;
  for (let i = 0; i < merged.length; i += 1) {
    hash = (hash * 31 + merged.charCodeAt(i)) % 1000000;
  }
  return hash.toString().padStart(6, '0');
}

function applyTeenNightMode(now, start = '23:00', end = '05:00') {
  const [sH, sM] = start.split(':').map(Number);
  const [eH, eM] = end.split(':').map(Number);
  const minutes = now.getHours() * 60 + now.getMinutes();
  const startMin = sH * 60 + sM;
  const endMin = eH * 60 + eM;
  if (startMin < endMin) {
    return minutes >= startMin && minutes < endMin;
  }
  return minutes >= startMin || minutes < endMin;
}

function coinPackEuroToCoins(amountEuro) {
  const base = Math.round(amountEuro * 100);
  const rounded = Math.round(base / 10) * 10;
  return rounded;
}

module.exports = {
  MessageEnvelope,
  safetyNumber,
  applyTeenNightMode,
  coinPackEuroToCoins
};
