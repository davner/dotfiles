const Tailwind = {
    inputnumber: {
        root: 'w-full inline-flex',
        input: {
            root: ({ props }) => ({
                className: classNames({ 'rounded-tr-none rounded-br-none': props.showButtons && props.buttonLayout == 'stacked' })
            })
        },
        buttongroup: ({ props }) => ({
            className: classNames({ 'flex flex-col': props.showButtons && props.buttonLayout == 'stacked' })
        }),
        incrementbutton: ({ props }) => ({
            className: classNames('flex !items-center !justify-center', {
                'rounded-br-none rounded-bl-none rounded-bl-none !p-0 flex-1 w-[3rem]': props.showButtons && props.buttonLayout == 'stacked'
            })
        }),
        decrementbutton: ({ props }) => ({
            className: classNames('flex !items-center !justify-center', {
                'rounded-tr-none rounded-tl-none rounded-tl-none !p-0 flex-1 w-[3rem]': props.showButtons && props.buttonLayout == 'stacked'
            })
        })
    }
}
