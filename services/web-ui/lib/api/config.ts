import axios from 'axios'

// Get hostname from environment variables
let hostname = process.env.NEXT_PUBLIC_HOSTNAME || process.env.HOSTNAME || 'http://localhost:3000'

// Add protocol if not present
if (!hostname.startsWith('http://') && !hostname.startsWith('https://')) {
  hostname = `https://${hostname}`
}

const apiClient = axios.create({
  baseURL: hostname,
  withCredentials: true, // Enable cookies for HttpOnly authentication
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
})

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      // Server responded with error status
      // Preserve status code for proper error handling
      const errorData = {
        ...error.response.data,
        status: error.response.status,
        statusText: error.response.statusText,
      }
      return Promise.reject(errorData)
    } else if (error.request) {
      // Request made but no response
      return Promise.reject({ message: 'Network error. Please check your connection.' })
    } else {
      // Something else happened
      return Promise.reject({ message: error.message })
    }
  }
)

export default apiClient
