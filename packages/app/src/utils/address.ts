import { Address, zeroAddress } from 'viem';

export const shortenAddress = (address: string, size: number = 4) => {
  return `${address.substring(0, 2 + size)}...${address.substring(
    address.length - size,
  )}`;
};

export const isSameAddress = (
  a: string | null | undefined,
  b: string | null | undefined,
) => {
  if (!a || !b) return false;
  return a.toLowerCase() === b.toLowerCase();
};

export const isNativeToken = (address: Address) =>
  isSameAddress(address, zeroAddress);
