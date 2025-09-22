import styled from '@emotion/styled';

import { InstrumentSans, OpticianSans } from '@/fonts';

interface AmountInputProps {
  label: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export const AmountInput: React.FC<AmountInputProps> = ({
  label,
  value,
  onChange,
  placeholder = '0',
}) => {
  return (
    <Container>
      <Label>{label}</Label>
      <Input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
      />
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  flex-direction: column;
  gap: 10px;
  align-items: flex-start;
  padding: 16px;
  background: #121819;
  border-radius: 8px;
  width: 100%;
`;

const Label = styled.span`
  font-family: ${OpticianSans.style.fontFamily};
  font-size: 24px;
  font-weight: 400;
  line-height: 1.3;
  color: #879a98;
`;

const Input = styled.input`
  font-family: ${InstrumentSans.style.fontFamily};
  font-size: 36px;
  font-weight: 500;
  line-height: 1.3;
  color: #fff;
  background: transparent;
  border: none;
  outline: none;
  width: 100%;

  &::placeholder {
    color: #fff;
    opacity: 0.7;
  }

  &:focus {
    outline: none;
  }
`;
