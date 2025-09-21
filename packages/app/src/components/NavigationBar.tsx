import { css } from '@emotion/react';
import styled from '@emotion/styled';
import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';

import { OpticianSans } from '@/fonts';

import { ConnectButton } from './ConnectButton';

const NAVIGATION_ITEMS = [
  { title: 'Interact', href: '#interact' },
  { title: 'Composition', href: '#composition' },
];

export const NavigationBar = () => {
  const scrollToTop = () => window.scrollTo({ top: 0, behavior: 'smooth' });

  const [isScrolled, setIsScrolled] = useState<boolean>(false);
  const navRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const handleScroll = () => {
      if (!navRef.current) {
        return;
      }
      const navHeight = navRef.current.offsetHeight;
      setIsScrolled(window.scrollY > navHeight);
    };

    window.addEventListener('scroll', handleScroll);
    handleScroll();

    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  }, []);

  return (
    <Wrapper ref={navRef} scrolled={isScrolled}>
      <Container>
        <Link href="/" onClick={() => scrollToTop()}>
          <Logo src="/assets/logos/crest-logo.svg" />
        </Link>

        <NavigationList>
          {NAVIGATION_ITEMS.map((item) => (
            <Link key={item.href} href={item.href}>
              <Button>{item.title}</Button>
            </Link>
          ))}
        </NavigationList>

        <Right>
          <ConnectButton />
        </Right>
      </Container>
    </Wrapper>
  );
};

type WrapperProps = {
  scrolled: boolean;
};
const Wrapper = styled.div<WrapperProps>`
  width: 100%;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;

  z-index: 100000;

  ${({ scrolled }) =>
    scrolled &&
    css`
      background-color: rgba(0, 0, 0, 0.1);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
    `}
`;
const Container = styled.div`
  margin: 0 auto;
  padding: 24px 20px;

  width: 100%;
  max-width: 1200px;

  display: flex;
  align-items: center;
  gap: 24px;
`;
const Logo = styled.img`
  width: 124px;
  height: 32px;
  object-fit: contain;
`;

const NavigationList = styled.nav`
  display: flex;
  align-items: center;
  gap: 6px;
`;
const Button = styled.button`
  width: fit-content;
  display: flex;
  padding: 4px 14px;
  justify-content: center;
  align-items: center;
  gap: 10px;

  border-radius: 8px;
  background: #253738;

  color: #fff;
  text-align: center;
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 20px;
  font-style: normal;
  font-weight: 400;
  line-height: 100%;
`;

const Right = styled.div`
  margin-left: auto;
  display: flex;
  align-items: center;
`;
