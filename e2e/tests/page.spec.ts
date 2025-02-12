import { test, expect } from '@playwright/test';

test.describe('page', () => {
  test.beforeEach(async ({page}) => {
    await page.goto('http://localhost:8080');
  })

  test('has title', async ({ page }) => {
    await expect(page).toHaveTitle(/Actix Elm Setup/);
  });

  test('has navigation inside header', async ({ page }) => {
    const headerElement = page.locator('header');
    await expect(headerElement.getByRole('navigation')).toBeVisible();
  });

  test('has login message inside header', async ({ page }) => {
    const headerElement = page.locator('header');
    await expect(headerElement.getByText(/You're /)).toBeVisible();
  });

  test('has language switcher inside header', async ({ page }) => {
    const headerElement = page.locator('header');
    const langSelect = headerElement.getByRole('combobox');
    await expect(langSelect).toBeVisible();
  });

  test('has privacy declaration and imprint inside footer', async ({ page }) => {
    const footerElement = page.locator('footer');
    await expect(footerElement.getByText('Privacy Declaration')).toBeVisible();
    await expect(footerElement.getByText('Imprint and Support')).toBeVisible();
  });

  test('has copyright and version info inside footer', async ({ page }) => {
    const footerElement = page.locator('footer');
    const copyrightElement = footerElement.getByText('©')
    await expect(copyrightElement).toBeVisible();
    await expect(footerElement.getByText('Version:')).toBeVisible();

    const copyrightElementText = await copyrightElement.textContent();
    const copyrightLastYear = Number(copyrightElementText.slice(-2));
    const thisYear = new Date().getFullYear() % 100;
    expect(copyrightLastYear).toBe(thisYear);
  });
});
