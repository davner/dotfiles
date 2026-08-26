// _app.js        
import { PrimeReactProvider } from "primereact/api";

export default function CustomCSSDemo() {

    const pt = {
        global: {
            css: `
                button {
                    padding: 2rem;
                }

                .p-ink {
                    display: block;
                    position: absolute;
                    background: rgba(255, 255, 255, 0.5);
                    border-radius: 100%;
                    transform: scale(0);
                    pointer-events: none;
                }

                .p-ink-active {
                    animation: ripple 0.4s linear;
                }

                @keyframes ripple {
                    100% {
                        opacity: 0;
                        transform: scale(2.5);
                    }
                }
            `
        }
    };

    return(
        <PrimeReactProvider value={{ pt }}>
            <App />
        </PrimeReactProvider>
    )
}
