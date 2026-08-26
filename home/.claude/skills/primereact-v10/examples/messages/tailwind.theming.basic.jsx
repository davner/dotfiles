const Tailwind = {  
    messages: {
        root: ({ state, index }) => {
            return {
                className: classNames('my-4 rounded-md', {
                    'bg-blue-100 border-solid border-0 border-l-4 border-blue-500 text-blue-700': state.messages[index] && state.messages[index].message.severity == 'info',
                    'bg-green-100 border-solid border-0 border-l-4 border-green-500 text-green-700': state.messages[index] && state.messages[index].message.severity == 'success',
                    'bg-orange-100 border-solid border-0 border-l-4 border-orange-500 text-orange-700': state.messages[index] && state.messages[index].message.severity == 'warn',
                    'bg-red-100 border-solid border-0 border-l-4 border-red-500 text-red-700': state.messages[index] && state.messages[index].message.severity == 'error'
                })
            };
        },
        wrapper: 'flex items-center py-5 px-7',
        icon: {
            className: classNames('w-6 h-6', 'text-lg mr-2')
        },
        text: 'text-base font-normal',
        button: {
            className: classNames('w-8 h-8 rounded-full bg-transparent transition duration-200 ease-in-out', 'ml-auto overflow-hidden relative', 'flex items-center justify-center', 'hover:bg-white/30')
        },
        transition: {
            enterFromClass: 'opacity-0',
            enterActiveClass: 'transition-opacity duration-300',
            leaveFromClass: 'max-h-40',
            leaveActiveClass: 'overflow-hidden transition-all duration-300 ease-in',
            leaveToClass: 'max-h-0 opacity-0 !m-0'
        }
    }
}
