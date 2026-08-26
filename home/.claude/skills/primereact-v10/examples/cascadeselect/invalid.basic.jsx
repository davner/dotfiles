<CascadeSelect invalid value={selectedCity} onChange={(e) => setSelectedCity(e.value)} options={countries} 
    optionLabel="cname" optionGroupLabel="name" optionGroupChildren={['states', 'cities']}
    className="w-full md:w-14rem" breakpoint="767px" placeholder="Select a City" style={{ minWidth: '14rem' }} />
