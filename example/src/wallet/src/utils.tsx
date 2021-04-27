// Temporary dummy method
export const randomId = (size = 8) => [...Array(size)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');
