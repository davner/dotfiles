//_app.js
import { PrimeReactProvider } from 'primereact/api';

root.attachShadow({ mode: 'open' }); // Open the shadowRoot
const mountHere = root.shadowRoot;

const options = { appendTo: mountHere, styleContainer: mountHere};

ReactDOM.createRoot(mountHere).render(
  <React.StrictMode>
    <PrimeReactProvider value={options}>
      <App />
    </PrimeReactProvider>
  </React.StrictMode>
);
