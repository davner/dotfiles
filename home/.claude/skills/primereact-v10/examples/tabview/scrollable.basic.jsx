<TabView scrollable>
    {scrollableTabs.map((tab) => {
        return (
            <TabPanel key={tab.title} header={tab.title}>
                <p className="m-0">{tab.content}</p>
            </TabPanel>
        );
    })}
</TabView>
