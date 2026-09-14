/**
 * Validacao de CPF por digitos verificadores (modulo 11), sem dependencias externas.
 * Aceita entrada com ou sem mascara (pontos/traco); normaliza internamente.
 */
export function normalizeCpf(rawCpf: string): string {
  return rawCpf.replace(/\D/g, "");
}

function calculateCheckDigit(digits: string, weightStart: number): number {
  let sum = 0;
  let weight = weightStart;

  for (const digit of digits) {
    sum += Number(digit) * weight;
    weight -= 1;
  }

  const remainder = sum % 11;
  return remainder < 2 ? 0 : 11 - remainder;
}

export function isValidCpf(rawCpf: string): boolean {
  const cpf = normalizeCpf(rawCpf);

  if (cpf.length !== 11) {
    return false;
  }

  // Sequencias de digitos repetidos (ex: 000.000.000-00) passam no calculo
  // do modulo 11, mas nao sao CPFs validos - excluidas explicitamente.
  if (/^(\d)\1{10}$/.test(cpf)) {
    return false;
  }

  const firstNineDigits = cpf.slice(0, 9);
  const firstCheckDigit = calculateCheckDigit(firstNineDigits, 10);

  const firstTenDigits = cpf.slice(0, 9) + String(firstCheckDigit);
  const secondCheckDigit = calculateCheckDigit(firstTenDigits, 11);

  return cpf === firstTenDigits + String(secondCheckDigit);
}
