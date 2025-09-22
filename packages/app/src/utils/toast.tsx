import styled from '@emotion/styled';
import { CheckCircle2, Loader2Icon, XCircle } from 'lucide-react';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import { TransactionReceipt } from 'viem';

import { Explorer } from './explorer';

export const toastTransaction = async (promise: Promise<TransactionReceipt>) =>
  toast
    .promise(promise, {
      pending: {
        render: () => `Sending Transaction...`,
        icon: <Loader2Icon className="animate-spin" />,
      },
      success: {
        render: ({ data }) => {
          const transactionHash = data.transactionHash;
          return (
            <div className="flex flex-col gap-1.5">
              <span className="inline-block">Transaction submitted!</span>
              <button
                className="text-xs !w-fit py-[5px] px-2 !h-fit tracking-tighter !bg-white/5 rounded-lg"
                onClick={() => {
                  const win = window.open(
                    Explorer.getTxLink(transactionHash),
                    '_blank',
                  );
                  win?.focus();
                }}
              >
                View in Mitoscan
              </button>
            </div>
          );
        },
        icon: <CheckCircle2 />,
      },
      error: {
        render: ({ data, props }: any) => {
          console.log([data.message], props);
          if (data?.message?.includes('User rejected the request')) {
            return 'Transaction rejected by user.';
          }
          const message = (data?.message || 'No message')
            .split('Contract Call:\n  address')[0]
            .trim();
          return `Transaction failed! ${message}`;
        },
        icon: <XCircle />,
      },
    })
    .catch(() => {});

export const StyledToastContainer = styled(ToastContainer)`
  &&&.Toastify__toast-container {
  }

  .Toastify__toast {
    background: #0a0f10;
    border: 1px solid #233838;
    border-radius: 0.75rem;
    color: #fff;
    font-family: inherit;
  }

  .Toastify__toast--error {
    background: #0a0f10;
    border: 1px solid rgba(248, 81, 73, 0.3);
  }

  .Toastify__toast--success {
    background: #0a0f10;
    border: 1px solid rgba(34, 134, 58, 0.3);
  }

  .Toastify__toast-body {
    color: #fff;
  }

  .Toastify__progress-bar {
    background: #256960;
  }

  .Toastify__progress-bar--error {
    background: #f85149;
  }

  .Toastify__progress-bar--success {
    background: #22863a;
  }

  .Toastify__close-button {
    color: #8b949e;
    opacity: 0.7;
  }

  .Toastify__close-button:hover {
    opacity: 1;
  }
`;