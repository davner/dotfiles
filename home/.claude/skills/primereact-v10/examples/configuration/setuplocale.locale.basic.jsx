// _app.js
import { PrimeReactProvider } from 'primereact/api';

export default function MyApp({ Component }) {
    const value = {
        locale: 'de',
        ...
    };

    return (
        <PrimeReactProvider value={value}>
            <Component />
        </PrimeReactProvider>
    );
}
