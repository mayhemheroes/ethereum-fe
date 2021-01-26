use crate::abi::utils as abi_utils;
use crate::yul::names;
use crate::yul::operations::abi as abi_operations;
use fe_analyzer::namespace::types::Contract;
use fe_analyzer::namespace::types::{
    AbiDecodeLocation,
    AbiEncoding,
};
use yultsur::*;

/// Builds a set of functions used to make calls to the given contract's public
/// functions.
pub fn contract_calls(contract: Contract) -> Vec<yul::Statement> {
    let contract_name = contract.name;
    contract
        .functions
        .into_iter()
        .map(|function| {
            // get the name of the call function and its parameters
            let function_name = names::contract_call(&contract_name, &function.name);
            let param_names = function
                .param_types
                .iter()
                .map(|typ| typ.abi_name())
                .collect::<Vec<String>>();

            // create a pair of identifiers and expressions for the parameters
            let (param_idents, param_exprs): (Vec<yul::Identifier>, Vec<yul::Expression>) = (0
                ..function.param_types.len())
                .into_iter()
                .map(|n| {
                    let name = format!("val_{}", n);
                    (identifier! { (name) }, identifier_expression! { (name) })
                })
                .collect::<Vec<_>>()
                .into_iter()
                .unzip();
            // the function selector must be added to the first 4 bytes of the calldata
            let selector = {
                let selector = abi_utils::func_selector(function.name.clone(), param_names);
                literal_expression! { (selector) }
            };
            // the operations used to encode the parameters
            let encoding_operation =
                abi_operations::encode(function.param_types.clone(), param_exprs.clone());
            // the size of the encoded data
            let encoding_size = abi_operations::encode_size(function.param_types, param_exprs);

            if function.return_type.is_empty_tuple() {
                // there is no return data to handle
                function_definition! {
                    function [function_name](addr, [param_idents...]) {
                        (let instart := alloc_mstoren([selector], 4))
                        (let insize := add(4, [encoding_size]))
                        (pop([encoding_operation]))
                        (pop((call((gas()), addr, 0, instart, insize, 0, 0))))
                    }
                }
            } else {
                let decoding_size =
                    abi_operations::static_encode_size(vec![function.return_type.clone()])
                        .expect("failed to get the static encoding size");
                let decoding_operation = abi_operations::decode(
                    vec![function.return_type],
                    identifier_expression! { outstart },
                    AbiDecodeLocation::Memory,
                )[0]
                .to_owned();
                // return data must be captured and decoded
                function_definition! {
                    function [function_name](addr, [param_idents...]) -> return_val {
                        (let instart := alloc_mstoren([selector], 4))
                        (let insize := add(4, [encoding_size]))
                        (pop([encoding_operation]))
                        (let outsize := [decoding_size])
                        (let outstart := alloc(outsize))
                        (pop((call((gas()), addr, 0, instart, insize, outstart, outsize))))
                        (return_val := [decoding_operation])
                    }
                }
            }
        })
        .collect()
}
