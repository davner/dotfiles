const Tailwind = {    
    picklist: {
        root: 'flex flex-col xl:flex-row',
        controls: 'flex flex-row xl:flex-col justify-center p-5',
        moveUpButton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        moveTopButton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        moveDownButton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        moveBottomButton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        listWrapper: 'grow shrink basis-2/4',
        header: {
            className: classNames(
                'bg-slate-50 text-slate-700 border border-gray-300 p-5 font-bold border-b-0 rounded-t-md',
                'dark:bg-gray-900 dark:text-white/80 dark:border-blue-900/40' //Dark Mode
            )
        },
        list: {
            className: classNames(
                'list-none m-0 p-0 overflow-auto min-h-[12rem] max-h-[24rem]',
                'border border-gray-300 bg-white text-gray-600 py-3 px-0 rounded-b-md outline-none',
                'dark:border-blue-900/40 dark:bg-gray-900 dark:text-white/80' //Dark Mode
            )
        },
        item: ({ context }) => ({
            className: classNames('relative cursor-pointer overflow-hidden', 'py-3 px-5 m-0 border-none text-gray-600 dark:text-white/80', 'transition duration-200', {
                'text-blue-700 bg-blue-500/20 dark:bg-blue-300/20': context.selected,
                'text-gray-600 dark:bg-blue-900/40': !context.selected
            })
        }),
        buttons: 'flex flex-row xl:flex-col justify-center p-5',
        movetotargetbutton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        movealltotargetbutton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        movetosourcebutton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        movealltosourcebutton: {
            root: {
                className: classNames(
                    'relative inline-flex cursor-pointer user-select-none items-center align-bottom text-center overflow-hidden m-0', // button component
                    'text-white bg-blue-500 border border-blue-500 rounded-md',
                    'transition duration-200 ease-in-out',
                    'justify-center px-0 py-3', // icon only
                    'mr-2 xl:mb-2', // orderlist button
                    'dark:bg-sky-300 dark:border-sky-300 dark:text-gray-900' //Dark Mode
                )
            },
            label: 'flex-initial w-0'
        },
        targetcontrols: 'flex flex-col justify-center p-5',
        targetwrapper: 'grow shrink basis-2/4',
        targetheader: {
            className: classNames(
                'bg-slate-50 text-slate-700 border border-gray-300 p-5 font-bold border-b-0 rounded-t-md',
                'dark:bg-gray-900 dark:text-white/80 dark:border-blue-900/40' //Dark Mode
            )
        },
        targetlist: {
            className: classNames(
                'list-none m-0 p-0 overflow-auto min-h-[12rem] max-h-[24rem]',
                'border border-gray-300 bg-white text-gray-600 py-3 px-0 rounded-b-md outline-none',
                'dark:border-blue-900/40 dark:bg-gray-900 dark:text-white/80' //Dark Mode
            )
        },
        transition: {
            timeout: 0,
            classNames: {
                enter: '!transition-none',
                enterActive: '!transition-none',
                exit: '!transition-none',
                exitActive: '!transition-none'
            }
        }
    },
}
