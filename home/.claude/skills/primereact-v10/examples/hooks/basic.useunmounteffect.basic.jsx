useUnmountEffect(() => {
    toast.current && toast.current.show({ severity: 'info', summary: 'Unmounted' });
});
