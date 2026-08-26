<FloatLabel>
    <CascadeSelect inputId="cs-city" value={selectedCity} onChange={(e) => setSelectedCity(e.value)} options={countries}
        optionLabel="cname" optionGroupLabel="name" optionGroupChildren={['states', 'cities']}
        className="w-full md:w-14rem" breakpoint="767px" style={{ minWidth: '14rem' }} />
    <label htmlFor="cs-city">City</label>
</FloatLabel>
