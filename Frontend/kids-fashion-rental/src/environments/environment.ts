export const environment = {
  production: false,
  // Use HTTP in dev to avoid ERR_CERT_AUTHORITY_INVALID (HTTPS: use https://localhost:7001/api after: dotnet dev-certs https --trust)
  apiUrl: 'http://localhost:5001/api'
};
