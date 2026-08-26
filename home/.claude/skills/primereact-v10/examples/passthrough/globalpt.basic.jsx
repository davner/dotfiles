// _app.js        
import { PrimeReactProvider } from "primereact/api";

export default function GlobalPTDemo() {

    const pt = {
        panel: {
            header: { className: 'bg-primary' }
        },
        autocomplete: {
            input: { root: { className: 'w-16rem' } }
        }
    };

    return(
        <PrimeReactProvider value={{ pt }}>
            <App />
        </PrimeReactProvider>
    )
}
