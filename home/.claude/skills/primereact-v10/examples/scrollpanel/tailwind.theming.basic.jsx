const Tailwind = {
    scrollpanel: {
        wrapper: 'overflow-hidden relative float-left h-full w-full z-[1]',
        content: 'box-border h-[calc(100%+18px)] overflow-scroll pr-[18px] pb-[18px] pl-0 pt-0 relative scrollbar-none w-[calc(100%+18px)] [&::-webkit-scrollbar]:hidden',
        barX: {
            className: classNames('relative bg-gray-100 invisible rounded cursor-pointer h-[9px] bottom-0 z-[2]', 'transition duration-[250ms] ease-linear')
        },
        barY: {
            className: classNames('relative bg-gray-100 rounded cursor-pointer w-[9px] top-0 z-[2]', 'transition duration-[250ms] ease-linear')
        }
    }
}
