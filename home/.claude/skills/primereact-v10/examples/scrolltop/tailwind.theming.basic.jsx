const Tailwind = {          
    scrolltop: {
        root: ({ props }) => ({
            className: classNames('fixed bottom-20 right-20 flex items-center justify-center', 'ml-auto', {
                '!bg-blue-500 hover:bg-blue-600 text-white rounded-md h-8 w-8': props.target == 'parent',
                '!bg-gray-700 hover:bg-gray-800 h-12 w-12 rounded-full text-white': props.target !== 'parent'
            })
        }),
        transition: {
            enterFromClass: 'opacity-0',
            enterActiveClass: 'transition-opacity duration-150',
            leaveActiveClass: 'transition-opacity duration-150',
            leaveToClass: 'opacity-0'
        }
    }
}
