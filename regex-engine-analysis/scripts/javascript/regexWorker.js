const { parentPort } = require('worker_threads');

parentPort.on('message', (message) => {
  const { regexString, input, linearTag } = message;
  const regex = linearTag ? new RegExp(regexString, 'l') : new RegExp(regexString);
  const result = regex.exec(input);
  parentPort.postMessage(result);
});
