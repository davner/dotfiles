<Paginator template={template1} first={first[0]} rows={rows[0]} totalRecords={120} onPageChange={(e) => onPageChange(e, 0)} leftContent={leftContent} rightContent={rightContent} />
<Paginator template={template2} first={first[1]} rows={rows[1]} totalRecords={120} onPageChange={(e) => onPageChange(e, 1)} className="justify-content-end" />
<Paginator template={template3} first={first[2]} rows={rows[2]} totalRecords={120} onPageChange={(e) => onPageChange(e, 2)} className="justify-content-start" />
