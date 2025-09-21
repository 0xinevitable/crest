import { ReactNode, useEffect, useState } from 'react';
import { createPortal } from 'react-dom';

type PortalProps = {
  children: ReactNode;
};

export const Portal: React.FC<PortalProps> = ({ children }) => {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    return () => setMounted(false);
  }, []);

  if (!mounted) return null;

  const portalElement = document.getElementById('portal');
  if (!portalElement) {
    console.warn('Portal element with id "portal" not found');
    return null;
  }

  return createPortal(children, portalElement);
};
