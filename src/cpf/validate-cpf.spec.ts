import { isValidCpf, normalizeCpf } from "./validate-cpf";

describe("normalizeCpf", () => {
  it("remove mascara (pontos e traco)", () => {
    expect(normalizeCpf("111.444.777-35")).toBe("11144477735");
  });

  it("mantem string ja normalizada inalterada", () => {
    expect(normalizeCpf("11144477735")).toBe("11144477735");
  });
});

describe("isValidCpf", () => {
  it("aceita um CPF valido conhecido, sem mascara", () => {
    expect(isValidCpf("11144477735")).toBe(true);
  });

  it("aceita o mesmo CPF valido, com mascara", () => {
    expect(isValidCpf("111.444.777-35")).toBe(true);
  });

  it("rejeita CPF com digito verificador incorreto", () => {
    expect(isValidCpf("11144477736")).toBe(false);
  });

  it("rejeita CPF com todos os digitos iguais", () => {
    expect(isValidCpf("00000000000")).toBe(false);
    expect(isValidCpf("11111111111")).toBe(false);
  });

  it("rejeita CPF com tamanho incorreto", () => {
    expect(isValidCpf("1114447773")).toBe(false);
    expect(isValidCpf("111444777355")).toBe(false);
  });

  it("rejeita entrada vazia ou nao numerica", () => {
    expect(isValidCpf("")).toBe(false);
    expect(isValidCpf("abc.def.ghi-jk")).toBe(false);
  });
});
