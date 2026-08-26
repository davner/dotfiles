import { PrimeReactProvider } from "primereact/api";
...
return(
    <PrimeReactProvider
        value={{
            pt: {
                button: {
                    root: { className: 'bg-teal-500 hover:bg-teal-700 cursor-pointer text-white p-3 border-round border-none flex gap-2' },
                    label: 'text-white font-bold text-xl', // OR { className: 'text-white font-bold text-xl' }
                    icon: 'text-white text-2xl'
                },
                panel: {
                    header: 'bg-primary border-primary',
                    content: 'border-primary text-lg text-primary-700',
                    title: 'bg-primary text-xl',
                    toggler: 'bg-primary hover:bg-primary-reverse'
                }
            }
        }}
    >
        <App />
    </PrimeReactProvider>
);
