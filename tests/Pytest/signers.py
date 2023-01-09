from starkware.starknet.services.api.gateway.transaction import InvokeFunction
from starkware.starknet.business_logic.transaction.objects import InternalTransaction, TransactionExecutionInfo
from nile.signer import Signer, from_call_to_call_array, TRANSACTION_VERSION

from starkware.starknet.public.abi import get_selector_from_name

class MockSigner():
    """
    Utility for sending signed transactions to an Account on Starknet.

    Parameters
    ----------

    private_key : int

    Examples
    ---------
    Constructing a MockSigner object

    >>> signer = MockSigner(1234)

    Sending a transaction

    >>> await signer.send_transaction(
            account, contract_address, 'contract_method', [arg_1]
        )

    Sending multiple transactions

    >>> await signer.send_transactions(
            account, [
                (contract_address, 'contract_method', [arg_1]),
                (contract_address, 'another_method', [arg_1, arg_2])
            ]
        )

    """

    def __init__(self, private_key):
        self.signer = Signer(private_key)
        self.public_key = self.signer.public_key

    async def send_transaction(self, account, to, selector_name, calldata, nonce=None, max_fee=0):
        return await self.send_transactions(account, [(to, selector_name, calldata)], nonce, max_fee)

    async def send_transactions(
        self,
        account,
        calls,
        nonce=None,
        max_fee=0
    ) -> TransactionExecutionInfo:
        # hexify address before passing to from_call_to_call_array
        build_calls = []
        for call in calls:
            build_call = list(call)
            build_call[0] = hex(build_call[0])
            build_calls.append(build_call)
        print(build_calls)
            
        raw_invocation = get_raw_invoke(account, build_calls)
        state = raw_invocation.state

        if nonce is None:
            nonce = await state.state.get_nonce_at(account.contract_address)

        _, sig_r, sig_s = self.signer.sign_transaction(account.contract_address, build_calls, nonce, max_fee)

        # craft invoke and execute tx
        external_tx = InvokeFunction(
            contract_address=account.contract_address,
            calldata=raw_invocation.calldata,
            entry_point_selector=None,
            signature=[sig_r, sig_s],
            max_fee=max_fee,
            version=TRANSACTION_VERSION,
            nonce=nonce,
        )

        tx = InternalTransaction.from_external(
            external_tx=external_tx, general_config=state.general_config
        )
        execution_info = await state.execute_tx(tx=tx)
        return execution_info

def get_raw_invoke(sender, calls):
    call_array = []
    for _, call in enumerate(calls):
        print('proxy_address',call[0],type(call[0]))
        print('getAdmin selector',get_selector_from_name(call[1]),type(get_selector_from_name(call[1])))
        
    """Return raw invoke, remove when test framework supports `invoke`."""
    call_array, calldata = from_call_to_call_array(calls)
    print('call_array',call_array)


    raw_invocation = sender.__execute__(call_array, calldata)
    return raw_invocation