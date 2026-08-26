<div className="flex flex-column align-items-center">
    <p className="font-bold text-xl mb-2">Authenticate Your Account</p>
    <p className="text-color-secondary block mb-5">Please enter the code sent to your phone.</p>
    <InputOtp value={token} onChange={(e) => setTokens(e.value)} length={6} inputTemplate={customInput} style={{gap: 0}}/>
    <div className="flex justify-content-between mt-5 align-self-stretch">
        <Button label="Resend Code" link className="p-0"></Button>
        <Button label="Submit Code"></Button>
    </div>
</div>
